import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global RouteObserver provider for tracking navigation events
final routeObserverProvider = Provider<RouteObserver<PageRoute>>((ref) {
  return RouteObserver<PageRoute>();
});