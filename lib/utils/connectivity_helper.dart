import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
enum NetworkStatus {
  online,
  offline,
  cellular,
  unknown
}
class ConnectivityHelper extends ChangeNotifier {
  static final ConnectivityHelper _instance = ConnectivityHelper._internal();
  factory ConnectivityHelper() => _instance;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  NetworkStatus _status = NetworkStatus.unknown;
  bool _isInitialized = false;
  NetworkStatus get status => _status;
  bool get isOnline => _status == NetworkStatus.online || _status == NetworkStatus.cellular;
  bool get isOffline => _status == NetworkStatus.offline;
  bool get isInitialized => _isInitialized;
  ConnectivityHelper._internal() {
    initConnectivity();
  }
  Future<void> initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      _isInitialized = true;
    } catch (e) {
      _status = NetworkStatus.unknown;
      debugPrint('Connectivity initialization error: $e');
    }
    notifyListeners();
  }
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    NetworkStatus newStatus = NetworkStatus.offline;
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
          newStatus = NetworkStatus.online;
          break;
        case ConnectivityResult.mobile:
          if (newStatus != NetworkStatus.online) {
            newStatus = NetworkStatus.cellular;
          }
          break;
        default:
          break;
      }
      if (newStatus == NetworkStatus.online) break;
    }
    if (results.isEmpty) {
      newStatus = NetworkStatus.offline;
    }
    if (_status != newStatus) {
      _status = newStatus;
      debugPrint('Connection status changed: $_status');
      notifyListeners();
    }
  }
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
      return isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
class ConnectivityWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showOfflineSnackbar;
  const ConnectivityWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showOfflineSnackbar = true,
  });
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityHelper(),
      builder: (context, _) {
        final connectivityHelper = ConnectivityHelper();
        if (connectivityHelper.isOffline && showOfflineSnackbar) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are offline. Some features may be limited.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          });
        }
        if (connectivityHelper.isOffline && offlineWidget != null) {
          return offlineWidget!;
        }
        return child;
      },
    );
  }
}
extension ConnectivityHelperExtension on BuildContext {
  ConnectivityHelper get connectivity => ConnectivityHelper();
  bool get isOnline => ConnectivityHelper().isOnline;
  void showOfflineIndicator() {
    ScaffoldMessenger.of(this).showSnackBar(
      const SnackBar(
        content: Text('No internet connection'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}