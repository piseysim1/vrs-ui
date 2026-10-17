import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/data/models/brand_model.dart';
import 'package:vrs_ui/app/data/providers/brand_provider.dart';

class BrandController extends GetxController {
  final api = BrandProvider();
  static const pageSize = 8;

  final brands = <BrandModel>[].obs;
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

  Future<void> load() async {
    try {
      isLoading.value = true;
      final res = await api.getBrands();
      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'Brands: HTTP ${res.statusCode}');
        return;
      }
      brands.value = _list(res.body)
          .whereType<Map>()
          .map((e) => BrandModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (page.value >= pageCount) page.value = pageCount - 1;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load brands: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------- search + pagination ----------
  List<BrandModel> get filtered {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return brands.toList();
    return brands
        .where(
          (b) =>
              (b.name).toLowerCase().contains(q) ||
              (b.code).toLowerCase().contains(q) ||
              (b.note ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  int get pageCount =>
      (filtered.length / pageSize).ceil().clamp(1, 9999).toInt();

  List<BrandModel> get pageItems {
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

  // ---------- helpers ----------
  bool nameExists(String name, {int? exceptId}) {
    final n = name.trim().toLowerCase();
    return brands.any((b) => b.id != exceptId && b.name.toLowerCase() == n);
  }

  String _makeCode(String name, {int? exceptId}) {
    var base = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (base.isEmpty) base = 'BRAND';
    if (base.length > 10) base = base.substring(0, 10);
    var code = base;
    var n = 1;
    while (brands.any((b) => b.id != exceptId && b.code == code)) {
      code = '$base${n++}';
    }
    return code;
  }

  void _refreshVehicleForm() {
    if (Get.isRegistered<AdminController>()) {
      Get.find<AdminController>().loadAll();
    }
  }

  // ---------- create / update ----------
  Future<bool> saveBrand({
    int? id,
    required String name,
    String code = '',
    String note = '',
  }) async {
    try {
      final n = name.trim();
      var c = code.trim().toUpperCase();
      if (c.isEmpty) c = _makeCode(n, exceptId: id);

      final body = {'code': c, 'name': n, 'note': note.trim()};
      final res = id == null
          ? await api.createBrand(body)
          : await api.updateBrand(id, {...body, 'id': id});
      print('SAVE BRAND ${res.statusCode}: ${res.body}');

      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'HTTP ${res.statusCode}: ${res.bodyString}');
        return false;
      }
      Get.snackbar('Success', id == null ? 'Brand created' : 'Brand updated');
      await load();
      _refreshVehicleForm();
      return true;
    } catch (e) {
      Get.snackbar('Error', '$e');
      return false;
    }
  }

  // ---------- delete ----------
  Future<bool> removeBrand(int id) async {
    final res = await api.deleteBrand(id);
    final ok = _ok(res.statusCode);
    Get.snackbar(
      ok ? 'Deleted' : 'Delete failed',
      ok ? 'Brand removed' : 'HTTP ${res.statusCode}: ${res.bodyString}',
    );
    await load();
    if (ok) _refreshVehicleForm();
    return ok;
  }
}
