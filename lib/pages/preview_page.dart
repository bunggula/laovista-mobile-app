import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final Map<String, String> formData;

  const PreviewPage({Key? key, required this.formData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fields = formData.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Request')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: fields.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final entry = fields[index];
            return ListTile(
              title: Text(
                _formatLabel(entry.key),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(entry.value),
            );
          },
        ),
      ),
    );
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'pickup_date':
        return 'Pickup Date';
      case 'name':
        return 'Full Name';
      case 'address':
        return 'Address';
      case 'birthdate':
        return 'Birthdate';
      case 'contact_number':
        return 'Contact Number';
      case 'purpose':
        return 'Purpose';
      case 'barangay_name':
        return 'Barangay';
      case 'captain':
        return 'Barangay Captain';
      case 'email':
        return 'Email';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }
}
