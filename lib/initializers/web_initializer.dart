import 'dart:html' as html;
import 'package:flutter/foundation.dart'; // For String.fromEnvironment

// This function will only be called on web builds due to conditional import
void platformSpecificInitialization() {
  // print('Running web-specific initialization...');
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  if (apiKey.isNotEmpty) {
    final scriptUrl = 'https://maps.googleapis.com/maps/api/js?key=$apiKey';
    // Check if script already exists (e.g., due to hot restart)
    if (html.document.querySelector('script[src="$scriptUrl"]') == null) {
      final script = html.ScriptElement()
        ..id = 'google-maps-sdk' // Optional ID
        ..src = scriptUrl
        ..async = true
        ..defer = true;
      // print('Injecting Google Maps script via web_initializer.');
      html.document.head?.append(script);
    }
  } else {
     // print('Web Initializer: Google Maps API Key not provided via --dart-define.');
  }
} 