import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/user_location_service.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../../domain/entities/category_entity.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  static const List<String> _supportedCurrencies = ['CDF', 'USD'];
  final _formKey = GlobalKey<FormState>();

  final _placeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(); // ville
  final _communeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<String, TextEditingController> _openingHoursControllers = {
    'monday': TextEditingController(text: '08:00 - 18:00'),
    'tuesday': TextEditingController(text: '08:00 - 18:00'),
    'wednesday': TextEditingController(text: '08:00 - 18:00'),
    'thursday': TextEditingController(text: '08:00 - 18:00'),
    'friday': TextEditingController(text: '08:00 - 20:00'),
    'saturday': TextEditingController(text: '10:00 - 20:00'),
    'sunday': TextEditingController(text: 'closed'),
  };
  static const List<MapEntry<String, String>> _openingDays = [
    MapEntry('monday', 'Lundi'),
    MapEntry('tuesday', 'Mardi'),
    MapEntry('wednesday', 'Mercredi'),
    MapEntry('thursday', 'Jeudi'),
    MapEntry('friday', 'Vendredi'),
    MapEntry('saturday', 'Samedi'),
    MapEntry('sunday', 'Dimanche'),
  ];
  final _picker = ImagePicker();
  final _userLocationService = UserLocationService();
  final List<XFile> _selectedPhotos = [];
  List<CategoryEntity> _categoryOptions = const [];
  final Set<int> _selectedCategoryIds = <int>{};
  final List<_PriceFormItem> _prices = [];

  bool _isSubmitting = false;
  bool _isLocating = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      final repository = CategoryRepositoryImpl(
        dioService: DioService(cacheService),
      );
      final categories = await repository.getCategories();
      if (!mounted) return;
      setState(() => _categoryOptions = categories);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chargement catégories impossible: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _communeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    for (final controller in _openingHoursControllers.values) {
      controller.dispose();
    }
    for (final item in _prices) {
      item.dispose();
    }
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une catégorie.')),
      );
      return;
    }

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Latitude/Longitude invalides ou manquantes.'),
        ),
      );
      return;
    }

    final pricesPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < _prices.length; i++) {
      final item = _prices[i];
      final label = item.labelController.text.trim();
      final priceText = item.priceController.text.trim();
      final rawCurrency = item.currencyController.text.trim().toUpperCase();
      final currency = _supportedCurrencies.contains(rawCurrency)
          ? rawCurrency
          : 'CDF';
      final description = item.descriptionController.text.trim();
      final hasAnyValue =
          label.isNotEmpty ||
          priceText.isNotEmpty ||
          currency.isNotEmpty ||
          description.isNotEmpty;
      if (!hasAnyValue) continue;

      final price = int.tryParse(priceText);
      if (label.isEmpty || price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menu ${i + 1}: label et prix (nombre entier) sont requis.',
            ),
          ),
        );
        return;
      }

      pricesPayload.add({
        'label': label,
        'price': price,
        'currency': currency,
        'description': description,
      });
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      final dioService = DioService(cacheService);

      final payload = <String, dynamic>{
        'categories': _selectedCategoryIds.toList()..sort(),
        'name': _placeNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'ville': _cityController.text.trim(),
        'commune': _communeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'website': _websiteController.text.trim(),
        'opening_hours': _openingHoursControllers.map(
          (day, controller) => MapEntry(day, controller.text.trim()),
        ),
        'prices': pricesPayload,
        'lat': lat,
        'lng': lng,
      };

      final response = await dioService.post(
        '/contributions/places',
        data: payload,
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'Échec de contribution');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Envoi impossible: $e')));
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci, votre contribution a été envoyée.')),
    );

    _formKey.currentState?.reset();
    _placeNameController.clear();
    _selectedCategoryIds.clear();
    _addressController.clear();
    _cityController.clear();
    _communeController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _phoneController.clear();
    _whatsappController.clear();
    _websiteController.clear();
    _openingHoursControllers['monday']?.text = '08:00 - 18:00';
    _openingHoursControllers['tuesday']?.text = '08:00 - 18:00';
    _openingHoursControllers['wednesday']?.text = '08:00 - 18:00';
    _openingHoursControllers['thursday']?.text = '08:00 - 18:00';
    _openingHoursControllers['friday']?.text = '08:00 - 20:00';
    _openingHoursControllers['saturday']?.text = '10:00 - 20:00';
    _openingHoursControllers['sunday']?.text = 'closed';
    for (final item in _prices) {
      item.dispose();
    }
    _prices.clear();
    _descriptionController.clear();
    _selectedPhotos.clear();
    setState(() {});
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await _userLocationService.getCurrentPosition();
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position récupérée avec succès.')),
      );
      setState(() {});
    } on UserLocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de récupérer la position.')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickPhotos() async {
    final remaining = 3 - _selectedPhotos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos autorisées.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 75,
      limit: remaining,
    );
    if (!mounted || picked.isEmpty) return;

    setState(() {
      _selectedPhotos.addAll(picked.take(remaining));
    });
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _selectedPhotos.length) return;
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _addPriceItem() {
    setState(() {
      _prices.add(_PriceFormItem());
    });
  }

  void _removePriceItem(int index) {
    if (index < 0 || index >= _prices.length) return;
    setState(() {
      final item = _prices.removeAt(index);
      item.dispose();
    });
  }

  InputDecoration _compactDecoration({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Contribuer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Ajouter un lieu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Contribuez pour élargir la communauté Mbokatour et aider les '
              'autres à découvrir de nouveaux lieux.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Renseignez les informations du lieu que vous souhaitez proposer.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _placeNameController,
              decoration: const InputDecoration(labelText: 'Nom du lieu'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom du lieu requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Catégories (categories)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_isLoadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (_categoryOptions.isEmpty)
              Text(
                'Aucune catégorie disponible.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryOptions.map((category) {
                  final id = category.id;
                  final icon = (category.icon ?? '').trim();
                  final label = icon.isEmpty
                      ? category.name
                      : '$icon ${category.name}';
                  return FilterChip(
                    label: Text(label),
                    selected: _selectedCategoryIds.contains(id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategoryIds.add(id);
                        } else {
                          _selectedCategoryIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adresse'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Adresse requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ville (ville)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ville requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _communeController,
              decoration: const InputDecoration(labelText: 'Commune'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: const Text('Prendre ma position actuelle'),
            ),
            if (_latitudeController.text.isNotEmpty &&
                _longitudeController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'lat: ${_latitudeController.text} | lng: ${_longitudeController.text}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Site web'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Horaires d\'ouverture (opening_hours)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._openingDays.map((entry) {
              final dayKey = entry.key;
              final dayLabel = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _openingHoursControllers[dayKey],
                  decoration: InputDecoration(
                    labelText: dayLabel,
                    hintText: 'Ex: 08:00 - 18:00 ou closed',
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Prix / Menus (prices)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addPriceItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_prices.isEmpty)
              Text(
                'Aucun menu ajouté.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ...List.generate(_prices.length, (index) {
              final item = _prices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 13),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Menu ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _removePriceItem(index),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Supprimer',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: item.labelController,
                        decoration: _compactDecoration(
                          labelText: 'Label',
                          hintText: 'Menu simple',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: item.priceController,
                              keyboardType: TextInputType.number,
                              decoration: _compactDecoration(
                                labelText: 'Prix',
                                hintText: '15000',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  _supportedCurrencies.contains(
                                    item.currencyController.text.trim(),
                                  )
                                  ? item.currencyController.text.trim()
                                  : 'CDF',
                              decoration: _compactDecoration(
                                labelText: 'Devise',
                              ),
                              items: _supportedCurrencies
                                  .map(
                                    (currency) => DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(currency),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                item.currencyController.text = value ?? 'CDF';
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: item.descriptionController,
                        decoration: _compactDecoration(
                          labelText: 'Description',
                          hintText: 'Plat + boisson',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Photos (${_selectedPhotos.length}/3)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            if (_selectedPhotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedPhotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final photo = _selectedPhotos[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(photo.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: () => _removePhoto(index),
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSubmitting ? 'Envoi...' : 'Envoyer la contribution',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceFormItem {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController currencyController = TextEditingController(
    text: 'CDF',
  );
  final TextEditingController descriptionController = TextEditingController();

  void dispose() {
    labelController.dispose();
    priceController.dispose();
    currencyController.dispose();
    descriptionController.dispose();
  }
}
