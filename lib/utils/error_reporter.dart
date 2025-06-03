import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:dwaya_app/utils/connectivity_helper.dart';

typedef ErrorReportCallback = void Function(Map<String, dynamic> errorData);

/// Centralized utility for handling and reporting errors in the app
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();
  factory ErrorReporter() => _instance;
  ErrorReporter._internal();
  
  DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;
  
  ErrorReportCallback? _reportCallback;
  
  static const int _maxLogEntries = 50;
  final List<Map<String, dynamic>> _errorLogs = [];
  
  /// Initializes error reporting with optional callback for external reporting
  Future<void> initialize({ErrorReportCallback? reportCallback}) async {
    _reportCallback = reportCallback;
    
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('Failed to get package info: $e');
    }
    
    FlutterError.onError = (FlutterErrorDetails details) {
      reportFlutterError(details);
      FlutterError.presentError(details);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(error, stack);
      return true;
    };
  }
  
  /// Reports a Flutter framework error
  void reportFlutterError(FlutterErrorDetails details) {
    reportError(details.exception, details.stack ?? StackTrace.empty, 
        context: details.context?.toString());
  }
  
  /// Reports an error with stack trace and optional context
  Future<void> reportError(dynamic error, StackTrace stack, {String? context}) async {
    final timestamp = DateTime.now();
    
    final Map<String, dynamic> errorData = {
      'timestamp': timestamp.toIso8601String(),
      'error': error.toString(),
      'stack': stack.toString(),
      'context': context ?? 'Unknown',
    };
    
    await _addEnvironmentInfo(errorData);
    
    _logErrorLocally(errorData);
    
    _reportCallback?.call(errorData);
    
    if (kDebugMode) {
      debugPrint('ERROR REPORT: ${errorData.toString()}');
    }
  }
  
  /// Adds device and environment information to error report
  Future<void> _addEnvironmentInfo(Map<String, dynamic> errorData) async {
    if (_packageInfo != null) {
      errorData['app'] = {
        'version': _packageInfo!.version,
        'buildNumber': _packageInfo!.buildNumber,
        'packageName': _packageInfo!.packageName,
      };
    }
    
    final connectivityHelper = ConnectivityHelper();
    errorData['networkStatus'] = connectivityHelper.status.toString();
    
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        errorData['device'] = {
          'platform': 'web',
          'browserName': webInfo.browserName.name,
          'appCodeName': webInfo.appCodeName,
          'appName': webInfo.appName,
          'appVersion': webInfo.appVersion,
          'deviceMemory': webInfo.deviceMemory,
          'language': webInfo.language,
          'platform': webInfo.platform,
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        errorData['device'] = {
          'platform': 'android',
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        errorData['device'] = {
          'platform': 'ios',
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        errorData['device'] = {
          'platform': 'windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        };
      } else {
        errorData['device'] = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      errorData['device'] = {
        'error': 'Failed to get device info: $e',
      };
    }
  }
  
  /// Logs error locally for later retrieval
  void _logErrorLocally(Map<String, dynamic> errorData) {
    _errorLogs.insert(0, errorData);
    
    if (_errorLogs.length > _maxLogEntries) {
      _errorLogs.removeRange(_maxLogEntries, _errorLogs.length);
    }
  }
  
  /// Returns list of recent error logs
  List<Map<String, dynamic>> getRecentErrorLogs() {
    return List.unmodifiable(_errorLogs);
  }
  
  /// Clears all stored error logs
  void clearErrorLogs() {
    _errorLogs.clear();
  }
  
  /// Shows an error dialog to the user
  static void showErrorDialog(BuildContext context, String message, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Shows an error message in a SnackBar
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}