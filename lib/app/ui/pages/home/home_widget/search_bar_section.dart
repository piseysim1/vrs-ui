import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';

class SearchBarSection extends StatefulWidget {
  const SearchBarSection({super.key});

  @override
  State<SearchBarSection> createState() => _SearchBarSectionState();
}

class _SearchBarSectionState extends State<SearchBarSection> {
  final HomeController controller = Get.find<HomeController>();
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  static const _primary = Color(0xFF003399);

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply(String value) {
    controller.searchQuery.value = value;
    _focus.unfocus();
  }

  void _clear() {
    _text.clear();
    controller.searchQuery.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Find your perfect ride for any occasion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              if (isMobile) ...[
                _searchField(),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: _searchButton()),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _searchField()),
                    const SizedBox(width: 12),
                    _searchButton(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _searchField() {
    return LayoutBuilder(
      builder: (context, box) {
        final popupWidth = box.maxWidth;

        return RawAutocomplete<VehicleModel>(
          textEditingController: _text,
          focusNode: _focus,
          optionsBuilder: (value) => controller.suggest(value.text),
          displayStringForOption: (v) => v.displayName,
          onSelected: (v) {
            _focus.unfocus();
            Get.toNamed('/vehicle/${v.id}');
          },
          fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textCtrl,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                if (v.trim().isEmpty) controller.searchQuery.value = '';
              },
              onSubmitted: (v) => _apply(v),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by brand or model (e.g. Toyota, Civic)',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textCtrl,
                  builder: (_, value, __) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: Colors.grey,
                          onPressed: _clear,
                        ),
                ),
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: popupWidth,
                      minWidth: popupWidth,
                      maxHeight: 380,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final v = options.elementAt(index);
                        final highlighted =
                            AutocompleteHighlightedOption.of(context) == index;
                        return _suggestionTile(
                          v,
                          highlighted,
                          () => onSelected(v),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _suggestionTile(VehicleModel v, bool highlighted, VoidCallback onTap) {
    final url = resolveImageUrl(v.imageUrl);
    final hasPrice = v.price != null && v.price! > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: highlighted ? const Color(0xFFF0F4FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 46,
                child: url == null
                    ? _thumbPlaceholder()
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${v.licensePlate}  •  ${v.colorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (hasPrice)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${v.price!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  if ((v.rateTypeName ?? '').isNotEmpty)
                    Text(
                      '/ ${v.rateTypeName}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: Colors.grey.shade100,
    child: const Icon(Icons.directions_car, color: Colors.grey, size: 22),
  );

  Widget _searchButton() {
    return ElevatedButton.icon(
      onPressed: () => _apply(_text.text),
      icon: const Icon(Icons.search, size: 18),
      label: const Text('Find Vehicles'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
