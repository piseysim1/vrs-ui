import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';
import 'package:vrs_ui/app/data/providers/file_provider.dart';

class ProfileController extends GetxController {
  final api = AdminProvider();

  final user = Rxn<Map<String, dynamic>>();
  final bookings = <BookingModel>[].obs;
  final loading = true.obs;
  final saving = false.obs;
  final editing = false.obs;

  final fullName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    fullName.dispose();
    phone.dispose();
    email.dispose();
    super.onClose();
  }

  void _showSuccessSnackbar(
    String title,
    String message, {
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  void _showErrorSnackbar(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  void _showInfoSnackbar(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade700,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.info_outline, color: Colors.white),
      duration: duration ?? const Duration(seconds: 4),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
  // --------------------------------

  List _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in const ['results', 'Results', 'items', 'data']) {
        if (d[k] is List) return d[k];
      }
    }
    return [];
  }

  bool _ok(int? c) => c == 200 || c == 201 || c == 204;

  Future<void> load() async {
    final uid = AuthService.userId;
    if (uid == null) {
      Get.offAllNamed('/login');
      return;
    }
    try {
      loading.value = true;
      final res = await Future.wait([api.getUsers(), api.getBookings()]);

      if (_ok(res[0].statusCode)) {
        final users = _list(
          res[0].body,
        ).map((e) => Map<String, dynamic>.from(e)).toList();
        final me = users.firstWhereOrNull(
          (u) => (u['id'] as num?)?.toInt() == uid,
        );
        user.value = me;
        _fill();

        // the photo comes from the database, so the navbar (and every other
        // device / web build) shows the same picture
        final p = '${me?['profile'] ?? ''}';
        if (p.isNotEmpty) AuthService.setAvatar(p);
      } else {
        _showErrorSnackbar(
          'Profile Load Error',
          'HTTP ${res[0].statusCode}: ${res[0].bodyString}',
        );
      }

      if (_ok(res[1].statusCode)) {
        bookings.value =
            _list(res[1].body)
                .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
                .where((b) => b.userId == uid)
                .toList()
              ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      }
    } finally {
      loading.value = false;
    }
  }

  void _fill() {
    final u = user.value;
    fullName.text = '${u?['fullName'] ?? ''}';
    phone.text = '${u?['phone'] ?? ''}';
    email.text = '${u?['email'] ?? ''}';
  }

  void cancelEdit() {
    _fill();
    editing.value = false;
  }

  Future<bool> save({String? profileUrl}) async {
    final u = user.value;
    if (u == null) return false;
    if (fullName.text.trim().isEmpty) {
      _showErrorSnackbar('Profile', 'Full name is required');
      return false;
    }
    saving.value = true;
    try {
      final body = {
        'id': u['id'],
        'roleId': u['roleId'],
        'username': u['username'],
        'fullName': fullName.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'profile': profileUrl ?? u['profile'],
      };
      final r = await api.updateUser((u['id'] as num).toInt(), body);
      print('UPDATE USER ${r.statusCode}: ${r.bodyString}');
      if (!_ok(r.statusCode)) {
        _showErrorSnackbar(
          'Update failed',
          'HTTP ${r.statusCode}: ${r.bodyString}',
          duration: const Duration(seconds: 6),
        );
        return false;
      }
      _showSuccessSnackbar('Saved', 'Your profile was updated');
      editing.value = false;
      await load();
      return true;
    } finally {
      saving.value = false;
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String name) async {
    final u = user.value;
    if (u == null) return;
    saving.value = true;
    try {
      final url = await FileProvider().uploadImage(bytes, name);
      print('AVATAR URL: $url');
      if (url == null) {
        _showErrorSnackbar('Upload failed', 'Could not upload $name');
        return;
      }
      final id = (u['id'] as num).toInt();
      final r = await api.updateUser(id, {
        'id': u['id'],
        'roleId': u['roleId'],
        'username': u['username'],
        'fullName': u['fullName'],
        'phone': u['phone'],
        'email': u['email'],
        'profile': url,
      });
      print('SAVE AVATAR ${r.statusCode}: ${r.bodyString}');
      if (!_ok(r.statusCode)) {
        _showErrorSnackbar(
          'Photo not saved',
          'HTTP ${r.statusCode}: ${r.bodyString}',
          duration: const Duration(seconds: 6),
        );
        return;
      }

      await load(); // read it back from the server

      final saved = '${user.value?['profile'] ?? ''}';
      if (saved.isEmpty) {
        // the API answered OK but did not store it
        _showInfoSnackbar(
          'Photo not stored',
          'The server accepted the update but "profile" is still empty. Check that the backend user update maps Profile.',
          duration: const Duration(seconds: 8),
        );
      } else {
        _showSuccessSnackbar('Saved', 'Profile photo updated');
      }
    } finally {
      saving.value = false;
    }
  }

  void logout() {
    AuthService.clear();
    Get.offAllNamed('/login');
  }
}
