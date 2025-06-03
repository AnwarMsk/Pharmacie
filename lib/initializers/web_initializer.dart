import 'dart:html' as html;
import 'package:flutter/foundation.dart';
void platformSpecificInitialization() {
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  if (apiKey.isNotEmpty) {
    final scriptUrl = 'https:
    if (html.document.querySelector('script[src="$scriptUrl"]') == null) {
      final script = html.ScriptElement()
        ..id = 'google-maps-sdk'
        ..src = scriptUrl
        ..async = true
        ..defer = true;
      html.document.head?.append(script);
    }
  } else {
    if (kDebugMode) {
      print('Web Initializer: Google Maps API Key not provided via --dart-define=GOOGLE_MAPS_API_KEY');
    }
  }
}