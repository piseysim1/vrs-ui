import 'package:get/get.dart';
import 'package:vrs_ui/app/data/models/customer_model.dart';
import 'package:vrs_ui/app/data/providers/customer_provider.dart';

// TODO: set this to the id of the "Customer" role in your roles table.
const kCustomerRoleId = 2;

class CustomerController extends GetxController {
  final api = CustomerProvider();
  static const pageSize = 8;

  final customers = <CustomerModel>[].obs;
  final isLoading = false.obs;
  final search = ''.obs;
  final page = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool _ok(int? c) => c == 200 || c == 201 || c == 204;

  List _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in const ['results', 'Results', 'items', 'Items', 'data']) {
        if (d[k] is List) return d[k];
      }
    }
    return [];
  }

  // ---------- fetch ----------
  Future<void> load() async {
    try {
      isLoading.value = true;
      final res = await api.getUsers();
      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'Users: HTTP ${res.statusCode}');
        return;
      }
      final all = _list(res.body)
          .whereType<Map>()
          .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      print('USERS loaded: ${all.length}');

      // only show customers (users that have no roleId are kept)
      customers.value = all
          .where((u) => u.roleId == null || u.roleId == kCustomerRoleId)
          .toList();

      if (page.value >= pageCount) page.value = pageCount - 1;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load customers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------- search + pagination ----------
  List<CustomerModel> get filtered {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return customers.toList();
    return customers
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phone.toLowerCase().contains(q),
        )
        .toList();
  }

  int get pageCount =>
      (filtered.length / pageSize).ceil().clamp(1, 9999).toInt();

  List<CustomerModel> get pageItems {
    final list = filtered;
    final start = (page.value * pageSize).clamp(0, list.length).toInt();
    final end = (start + pageSize).clamp(0, list.length).toInt();
    return list.sublist(start, end);
  }

  void setSearch(String v) {
    search.value = v;
    page.value = 0;
  }

  void nextPage() {
    if (page.value < pageCount - 1) page.value++;
  }

  void prevPage() {
    if (page.value > 0) page.value--;
  }

  bool usernameExists(String u, {int? exceptId}) {
    final n = u.trim().toLowerCase();
    return customers.any(
      (c) => c.id != exceptId && c.username.toLowerCase() == n,
    );
  }

  // ---------- create / update ----------
  // On edit, leave [password] empty to keep the current one.
  Future<bool> saveCustomer({
    int? id,
    required String fullName,
    required String username,
    required String phone,
    required String email,
    String password = '',
    String? profile,
    int? roleId,
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username.trim(),
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'profile': profile ?? '',
        'roleId': roleId ?? kCustomerRoleId,
        if (password.isNotEmpty) 'password': password,
      };
      final res = id == null
          ? await api.createUser(body)
          : await api.updateUser(id, {...body, 'id': id});
      print('SAVE USER ${res.statusCode}: ${res.body}');

      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'HTTP ${res.statusCode}: ${res.bodyString}');
        return false;
      }
      Get.snackbar(
        'Success',
        id == null ? 'Customer created' : 'Customer updated',
      );
      await load();
      return true;
    } catch (e) {
      Get.snackbar('Error', '$e');
      return false;
    }
  }

  // ---------- delete ----------
  Future<bool> removeCustomer(int id) async {
    final res = await api.deleteUser(id);
    final ok = _ok(res.statusCode);
    Get.snackbar(
      ok ? 'Deleted' : 'Delete failed',
      ok ? 'Customer removed' : 'HTTP ${res.statusCode}: ${res.bodyString}',
    );
    await load();
    return ok;
  }
}