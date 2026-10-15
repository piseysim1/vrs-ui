import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!AuthService.isLoggedIn) return const RouteSettings(name: '/login');
    if (!AuthService.can('vehicle.view')) return const RouteSettings(name: '/home');
    return null;
  }
}