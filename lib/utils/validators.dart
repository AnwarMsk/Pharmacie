import 'dart:async';
import 'package:flutter/material.dart';

class Validator {
  /// Validates if the given string is a properly formatted email address
  static bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(email);
  }

  /// Checks if password meets minimum length requirement of 6 characters
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validates if password meets strong password criteria (8+ chars, uppercase, lowercase, number, special char)
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  /// Validates if the phone number follows international format
  static bool isValidPhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^\+?[0-9]{6,15}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Checks if a string is not null and not empty after trimming
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validates if a coordinate value is within valid range (-180 to 180)
  static bool isValidCoordinate(double? value) {
    if (value == null) return false;
    return value >= -180 && value <= 180;
  }

  /// Checks if a string can be parsed as a number
  static bool isNumeric(String value) {
    if (value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  /// Validates if a string is a properly formatted URL
  static bool isValidUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if a search query is valid (minimum 2 characters)
  static bool isValidSearchQuery(String query) {
    return query.trim().length >= 2;
  }

  /// Validates email and returns error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password and returns error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isValidPassword(value)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates strong password and returns specific feedback for missing requirements
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    List<String> missingRequirements = [];
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      missingRequirements.add('uppercase letter');
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      missingRequirements.add('lowercase letter');
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      missingRequirements.add('number');
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      missingRequirements.add('special character');
    }
    
    if (missingRequirements.isNotEmpty) {
      return 'Password must include a ${missingRequirements.join(', ')}';
    }
    
    return null;
  }

  /// Validates phone number and returns error message if invalid
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhoneNumber(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates required field and returns error message if empty
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates URL and returns error message if invalid
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (!isValidUrl(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Creates a debouncer for search inputs to prevent rapid API calls
  static Debouncer createDebouncer({Duration duration = const Duration(milliseconds: 500)}) {
    return Debouncer(duration: duration);
  }
}

/// Utility class for throttling rapid user inputs
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({required this.duration});

  /// Executes the callback after the specified duration
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }

  /// Cancels any pending timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Form utility methods for common form operations
class FormUtils {
  /// Shows an error message in a SnackBar
  static void showFormError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a success message in a SnackBar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Validates form and shows error if invalid
  static bool validateAndShowError(GlobalKey<FormState> formKey, BuildContext context) {
    if (formKey.currentState?.validate() ?? false) {
      return true;
    } else {
      showFormError(context, 'Please fix the errors in the form');
      return false;
    }
  }
}