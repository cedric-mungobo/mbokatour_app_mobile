import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/user_location_service.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
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
  final _openingHoursController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final _userLocationService = UserLocationService();
  final List<XFile> _selectedPhotos = [];
  final List<String> _categoryOptions = const [
    'Bars',
    'Restaurants',
    'Hôtels',
    'Loisirs',
    'Culture',
    'Shopping',
    'Autres',
  ];
  String? _selectedCategory;

  bool _isSubmitting = false;
  bool _isLocating = false;

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
    _openingHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci, votre contribution a été envoyée.')),
    );

    _formKey.currentState?.reset();
    _placeNameController.clear();
    _selectedCategory = null;
    _addressController.clear();
    _cityController.clear();
    _communeController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _phoneController.clear();
    _whatsappController.clear();
    _websiteController.clear();
    _openingHoursController.clear();
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
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie (categories)',
              ),
              items: _categoryOptions
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Catégorie requise';
                }
                return null;
              },
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
            TextFormField(
              controller: _openingHoursController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Horaires d\'ouverture (opening_hours)',
                hintText: 'Ex: monday: 09:00-18:00',
              ),
            ),
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
