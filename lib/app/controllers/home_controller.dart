import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/data/models/brand_model.dart';
import 'package:vrs_ui/app/data/models/rate_model.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/home_provider.dart';

class HomeController extends GetxController {
  final HomeProvider homeProvider = HomeProvider();
  static bool pendingAbout = false;
  var brandList = <BrandModel>[].obs;
  var vehicleList = <VehicleModel>[].obs;
  var rateList = <RateModel>[].obs;

  var isLoadingBrands = false.obs;
  var isLoadingVehicles = false.obs;
  var selectedBrandId = (-1).obs;
  final GlobalKey aboutKey = GlobalKey();
  @override
  void onInit() {
    super.onInit();
    fetchBrands();
    loadVehiclesWithPrices();
  }

  void scrollToAbout() {
    final ctx = aboutKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.0, // 0.0 puts the section at the top of the viewport
    );
  }

  var searchQuery = ''.obs;
  bool _matches(VehicleModel v, String q) {
    if (q.isEmpty) return true;
    return v.modelName.toLowerCase().contains(q) ||
        v.brandName.toLowerCase().contains(q) ||
        v.displayName.toLowerCase().contains(q) ||
        v.licensePlate.toLowerCase().contains(q);
  }

  List<VehicleModel> get filteredVehicles {
    final q = searchQuery.value.trim().toLowerCase();
    return vehicleList.where((v) {
      final matchBrand =
          selectedBrandId.value == -1 || v.brandId == selectedBrandId.value;
      return matchBrand && _matches(v, q);
    }).toList();
  }

  List<VehicleModel> suggest(String text) {
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return vehicleList.where((v) => _matches(v, q)).take(6).toList();
  }

  List _extractList(dynamic data) {
    if (data is Map) return data['results'] ?? data['Results'] ?? [];
    if (data is List) return data;
    return [];
  }

  Future<void> fetchBrands() async {
    try {
      isLoadingBrands.value = true;
      final response = await homeProvider.getBrands();
      if (response.statusCode == 200 && response.body != null) {
        brandList.value = _extractList(
          response.body,
        ).map((e) => BrandModel.fromJson(e)).toList();
      } else {
        Get.snackbar(
          'Error',
          'HTTP ${response.statusCode}: ${response.statusText}',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load brands: $e');
    } finally {
      isLoadingBrands.value = false;
    }
  }

  Future<void> loadVehiclesWithPrices() async {
    try {
      isLoadingVehicles.value = true;

      final results = await Future.wait([
        homeProvider.getVehicles(),
        homeProvider.getRates(),
      ]);
      final vehicleRes = results[0];
      final rateRes = results[1];

      if (rateRes.statusCode == 200 && rateRes.body != null) {
        rateList.value = _extractList(
          rateRes.body,
        ).map((e) => RateModel.fromJson(e)).toList();
      }

      if (vehicleRes.statusCode == 200 && vehicleRes.body != null) {
        final vehicles = _extractList(
          vehicleRes.body,
        ).map((e) => VehicleModel.fromJson(e)).toList();

        for (final v in vehicles) {
          final rate = _findRate(v);
          v.price = rate?.price;
          v.rateTypeName = rate?.rateTypeName;
        }
        vehicleList.value = vehicles;
      } else {
        Get.snackbar(
          'Error',
          'HTTP ${vehicleRes.statusCode}: ${vehicleRes.statusText}',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load vehicles: $e');
    } finally {
      isLoadingVehicles.value = false;
    }
  }

  RateModel? _findRate(VehicleModel v) {
    for (final r in rateList) {
      if (r.modelId == v.modelId && r.rateTypeId == 2 && r.price > 0) return r;
    }

    for (final r in rateList) {
      if (v.rateId != null && r.id == v.rateId && r.price > 0) return r;
    }

    for (final r in rateList) {
      if (r.modelId == v.modelId && r.price > 0) return r;
    }
    return null;
  }

  IconData getBrandIcon(String brandName) {
    switch (brandName.toLowerCase()) {
      case 'mercedes':
      case 'mercedes-benz':
      case 'bmw':
      case 'tesla':
        return Icons.directions_car_rounded;
      case 'electric':
        return Icons.electric_car;
      case 'suv':
        return Icons.directions_car_filled;
      case 'cargo':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }
}
