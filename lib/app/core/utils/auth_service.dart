import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  AuthService._();
  static final _box = GetStorage();
  static final avatar = RxnString();
  static const _all = <String>{
    'vehicle.view',
    'vehicle.create',
    'vehicle.edit',
    'vehicle.delete',
  };

  static const _rolePermissions = <String, Set<String>>{
    'admin': _all,
    'administrator': _all,
    'superadmin': _all,
  };
  static String? get savedAvatar {
    final id = userId;
    if (id == null) return null;
    final v = _box.read('avatar_$id');
    return (v == null || v.toString().isEmpty) ? null : v.toString();
  }

  static void setAvatar(String url) {
    final id = userId;
    if (id != null) _box.write('avatar_$id', url);
    avatar.value = url;
  }

  static String? get token {
    final t = _box.read('token');
    return (t == null || t.toString().isEmpty) ? null : t.toString();
  }

  static bool get isLoggedIn => token != null;

  static Map<String, dynamic> _payload() {
    final t = token;
    if (t == null) return {};
    final parts = t.split('.');
    if (parts.length != 3) return {};
    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static int? get userId {
    final v = _payload()['uid'];
    final fromToken = v is int ? v : int.tryParse('$v');
    if (fromToken != null) return fromToken;
    final saved = _box.read('userId');
    return saved is int ? saved : int.tryParse('$saved');
  }

  static Map<String, dynamic> get debugClaims => _payload();
  static List<String> get roles {
    final p = _payload();
    final out = <String>[];
    for (final key in const [
      'role',
      'roles',
      'roleName',
      'RoleId',
      'roleId',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
    ]) {
      final v = p[key];
      if (v is String) out.add(v);
      if (v is List) out.addAll(v.map((e) => e.toString()));
      if (v is int) out.add(v.toString());
    }

    // 2. Fallback to GetStorage local values if JWT has no role claims
    if (out.isEmpty) {
      final savedRole = _box.read('role');
      if (savedRole is String) out.add(savedRole);
      if (savedRole is List) out.addAll(savedRole.map((e) => e.toString()));

      final savedRoleId = _box.read('roleId');
      if (savedRoleId != null) out.add(savedRoleId.toString());
    }

    // 3. Normalize roles and map numeric role IDs (e.g. 1 -> admin)
    final normalized = <String>[];
    for (final r in out) {
      final clean = r.toLowerCase().trim();
      if (clean == '1') {
        normalized.add('admin');
      } else {
        normalized.add(clean);
      }
    }

    return normalized.toSet().toList();
  }

  static bool can(String permission) =>
      roles.any((r) => _rolePermissions[r]?.contains(permission) ?? false);

  static void clear() {
    _box.remove('token');
    _box.remove('refreshToken');
    _box.remove('role');
    _box.remove('roleId');
    _box.remove('userId');
    _box.remove('fullName');
  }
}
