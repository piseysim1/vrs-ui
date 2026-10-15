import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/data/models/location_model.dart';
import 'package:vrs_ui/app/data/providers/location_provider.dart';

class LocationController extends GetxController {
  final api = LocationProvider();
  static const pageSize = 8;

  final locations = <LocationModel>[].obs;
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
      final res = await api.getLocations();
      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'Locations: HTTP ${res.statusCode}');
        return;
      }
      locations.value = _list(res.body)
          .whereType<Map>()
          .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // keep the current page valid after a delete or a new search
      if (page.value >= pageCount) page.value = pageCount - 1;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load locations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------- search + pagination ----------
  List<LocationModel> get filtered {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return locations.toList();
    return locations
        .where(
          (b) =>
              b.name.toLowerCase().contains(q) ||
              b.code.toLowerCase().contains(q) ||
              b.note.toLowerCase().contains(q),
        )
        .toList();
  }

  int get pageCount =>
      (filtered.length / pageSize).ceil().clamp(1, 9999).toInt();

  List<LocationModel> get pageItems {
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
    return locations.any((b) => b.id != exceptId && b.name.toLowerCase() == n);
  }

  String _makeCode(String name, {int? exceptId}) {
    var base = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (base.isEmpty) base = 'LOCATION';
    if (base.length > 10) base = base.substring(0, 10);
    var code = base;
    var n = 1;
    while (locations.any((b) => b.id != exceptId && b.code == code)) {
      code = '$base${n++}';
    }
    return code;
  }

  // The vehicle form reads its location dropdown from AdminController,
  // so reload it whenever a location changes.
  void _refreshVehicleForm() {
    if (Get.isRegistered<AdminController>()) {
      Get.find<AdminController>().loadAll();
    }
  }

  // ---------- create / update ----------
  Future<bool> saveLocation({
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
          ? await api.createLocation(body)
          : await api.updateLocation(id, {...body, 'id': id});
      print('SAVE LOCATION ${res.statusCode}: ${res.body}');

      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'HTTP ${res.statusCode}: ${res.bodyString}');
        return false;
      }
      Get.snackbar('Success', id == null ? 'Location created' : 'Location updated');
      await load();
      _refreshVehicleForm();
      return true;
    } catch (e) {
      Get.snackbar('Error', '$e');
      return false;
    }
  }

  // ---------- delete ----------
  Future<bool> removeLocation(int id) async {
    final res = await api.deleteLocation(id);
    final ok = _ok(res.statusCode);
    Get.snackbar(
      ok ? 'Deleted' : 'Delete failed',
      ok ? 'Location removed' : 'HTTP ${res.statusCode}: ${res.bodyString}',
    );
    await load();
    if (ok) _refreshVehicleForm();
    return ok;
  }
}