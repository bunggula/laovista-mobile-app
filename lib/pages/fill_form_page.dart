import 'dart:convert';
import 'package:Laovista/api_service.dart';
import 'package:Laovista/pages/RequestSuccessPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class FillFormPage extends StatefulWidget {
  final String title;
  final Map<String, String> initialValues;
  final String token;
  final int barangayId;
  final String? documentId;

  const FillFormPage({
    Key? key,
    required this.title,
    required this.initialValues,
    required this.token,
    required this.barangayId,
    this.documentId,
  }) : super(key: key);

  @override
  State<FillFormPage> createState() => _FillFormPageState();
}

class _FillFormPageState extends State<FillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController otherPurposeController = TextEditingController();
  bool isSubmitting = false;
  bool isLoading = true;
  bool isOtherPurpose = false;

  List<Map<String, dynamic>> formFields = [];
  List<Map<String, dynamic>> purposes = [];
  Map<String, dynamic>? selectedPurpose;

  @override
  void initState() {
    super.initState();
    fetchFormData();
  }

 Future<void> fetchFormData() async {
  try {
    final api = ApiService();

    // Fetch dynamic fields
    final fieldData = await api.getDocumentFields(
      token: widget.token,
      documentId: widget.documentId!,
    );
    formFields = (fieldData['fields'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    for (var field in formFields) {
      _controllers[field['key']] =
          TextEditingController(text: widget.initialValues[field['key']] ?? '');
    }

    // Fetch purposes
    final purposeData = await api.getDocumentPurposes(
      token: widget.token,
      documentId: widget.documentId!,
    );
    purposes = (purposeData['purposes'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Add "Others" option
    purposes.add({'purpose': 'Others', 'price': 0});

    // ❌ Remove this line:
    // if (purposes.isNotEmpty) selectedPurpose = purposes.first;

    // ✅ Set selectedPurpose to null for placeholder
    selectedPurpose = null;

    setState(() => isLoading = false);
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to load form: $e')),
    );
  }
}


  void showConfirmationDialog() {
 if (selectedPurpose == null) {
   AwesomeDialog(
  context: context,
  dialogType: DialogType.warning,
  animType: AnimType.bottomSlide,
  title: 'Incomplete Form',
  desc: 'Please select a purpose before submitting your request.',
  btnOkOnPress: () {},
  btnOkColor: Colors.blue, // ✅ dito mo ginagawa blue
).show();
    return;
  }

  if (isOtherPurpose && otherPurposeController.text.isEmpty) {
  AwesomeDialog(
  context: context,
  dialogType: DialogType.warning,
  animType: AnimType.bottomSlide,
  title: 'Specify Purpose',
  desc: 'Please fill in your custom purpose before proceeding.',
  btnOkOnPress: () {},
  btnOkColor: Colors.blue, // ✅ blue din
).show();

    return;
  }

    final purposeText = isOtherPurpose
        ? '${otherPurposeController.text} (₱${selectedPurpose!['price']})'
        : '${selectedPurpose!['purpose']} (₱${selectedPurpose!['price']})';

    String requesterName = widget.initialValues['first_name'] ?? '';
    final middleName = widget.initialValues['middle_name'] ?? '';
    final lastName = widget.initialValues['last_name'] ?? '';
    if (middleName.isNotEmpty) requesterName += ' $middleName';
    if (lastName.isNotEmpty) requesterName += ' $lastName';

AwesomeDialog(
  context: context,
  dialogType: DialogType.info,
  animType: AnimType.bottomSlide,
  headerAnimationLoop: false,
  title: 'Confirm Your Request',
  body: SingleChildScrollView(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document & Purpose Section
          Text(
            'Document Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
              children: [
                TextSpan(text: 'Document: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '${widget.title}\n'),
                TextSpan(text: 'Purpose: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$purposeText\n'),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Colors.blueGrey),

          // Requester Info Section
          Text(
            'Requester Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
              children: [
                TextSpan(text: 'Name: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$requesterName\n'),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Colors.blueGrey),

          // Dynamic form fields
          ...formFields.map((field) {
            final key = field['key'];
            final label = field['label'];

            String displayValue = _controllers[key]?.text ?? '';

            if (field['type'] == 'date' && displayValue.isNotEmpty) {
              try {
                final parsedDate = DateFormat('yyyy-MM-dd').parse(displayValue);
                displayValue = DateFormat('MMMM d, yyyy').format(parsedDate);
              } catch (_) {}
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    TextSpan(
                        text: '$label: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade700,
                        )),
                    TextSpan(text: displayValue),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    ),
  ),
  btnCancelText: 'Edit',
  btnCancelOnPress: () {},
  btnOkText: 'Confirm',
  btnOkOnPress: () => submitDocument(),
  
).show();
  }

  Future<void> submitDocument() async {
 if (!_formKey.currentState!.validate()) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.warning,
    animType: AnimType.bottomSlide,
    title: 'Incomplete Form',
    desc: 'Please complete all required fields before submitting.',
    btnOkOnPress: () {},
    btnOkColor: Colors.orange.shade700,
  ).show();
  return;
}


    if (selectedPurpose == null || (isOtherPurpose && otherPurposeController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a purpose.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final api = ApiService();

    final formData = <String, String>{
      for (var field in formFields)
        field['key'] as String: _controllers[field['key']]!.text.trim(),
      'purpose': isOtherPurpose ? otherPurposeController.text.trim() : selectedPurpose!['purpose'],
    };

    try {
      
     final actualIsCustomPurpose = isOtherPurpose && otherPurposeController.text.trim().isNotEmpty;

final response = await api.submitDocumentRequest(
  token: widget.token,
  barangayId: widget.barangayId,
  title: widget.title,
  templateKey: widget.documentId,
  fields: formData,
  purpose: formData['purpose']!,
  price: isOtherPurpose ? null : selectedPurpose!['price'].toString(),
   isCustomPurpose: actualIsCustomPurpose,
);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final referenceCode = data['reference_code'];
        if (referenceCode != null && referenceCode.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RequestSuccessPage(referenceCode: referenceCode),
            ),
          );
        }
      } else if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        final lastRequest = data['last_request'];
        final createdAtUtc = DateTime.parse(lastRequest['created_at']);
        final formattedDate = DateFormat('MMMM d, yyyy h:mm a').format(createdAtUtc.toLocal());

        bool? proceed = false;
        await AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.bottomSlide,
          headerAnimationLoop: false,
          title: 'Duplicate Request Detected',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('There is an existing request for:', style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 6),
              Text('"${widget.title}"', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  children: [
                    TextSpan(text: 'Reference: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${lastRequest['reference_code']}\n'),
                    TextSpan(text: 'Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${lastRequest['status']}\n'),
                    TextSpan(text: 'Created At: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: formattedDate),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Do you still want to proceed?', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
          btnCancelText: 'Cancel',
          btnCancelOnPress: () => proceed = false,
          btnOkText: 'Proceed',
          btnOkOnPress: () => proceed = true,
        ).show();

   if (proceed == true) {
  final resendResponse = await api.submitDocumentRequest(
    token: widget.token,
    barangayId: widget.barangayId,
    title: widget.title,
    templateKey: widget.documentId,
    fields: formData,
    purpose: formData['purpose']!,
    price: isOtherPurpose ? null : selectedPurpose!['price'].toString(),
    isCustomPurpose: actualIsCustomPurpose, // ✅ dito
    force: true,
  );


          if (resendResponse.statusCode == 201) {
            final data = jsonDecode(resendResponse.body);
            final referenceCode = data['reference_code'];
            if (referenceCode != null && referenceCode.isNotEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestSuccessPage(referenceCode: referenceCode),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Submission failed! (${resendResponse.statusCode})')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission canceled.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Submission failed! (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

 Widget _buildField(Map<String, dynamic> field) {
  final key = field['key'] as String;
  final type = field['type'] as String;
  final label = field['label'] as String;

  if (type == 'date') {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        
    final selectedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(1900), // ✅ puwedeng mamili kahit anong nakaraan
        lastDate: DateTime(now.year + 50), // ✅ puwedeng mamili hanggang 50 years future
      );

       if (selectedDate != null) {
  _controllers[key]?.text = DateFormat('MMMM d, yyyy').format(selectedDate);
}

      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ),
    );
  } else if (type == 'number') {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  } else {
    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.blue.shade700,
    appBar: AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Container(
      // Make sure it fills the entire screen
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade200, // top
            Colors.blue.shade50,  // bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (purposes.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: selectedPurpose,
                              hint: const Text('Please select a purpose'),
                              decoration: InputDecoration(
                                labelText: 'Purpose',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: purposes
                                  .map((p) =>
                                      DropdownMenuItem<Map<String, dynamic>>(
                                        value: p,
                                        child: Text(p['purpose']),
                                      ))
                                  .toList(),
                            onChanged: (val) {
  setState(() {
    selectedPurpose = val;
    isOtherPurpose = val?['purpose']?.toString().trim() == 'Others';
  });

  if (isOtherPurpose) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      title: 'Notice',
      desc: 'Price for "Others" is not yet available. The Barangay Secretary will assign it upon approval.',
      btnOkOnPress: () {},
      btnOkColor: Colors.blue,
    ).show();
  }

  print('Selected purpose: ${val?['purpose']}, isOtherPurpose: $isOtherPurpose');
},

                              validator: (value) => value == null
                                  ? 'Please select a purpose'
                                  : null,
                            ),
                            if (isOtherPurpose)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextFormField(
                                  controller: otherPurposeController,
                                  decoration: InputDecoration(
                                    labelText: 'Specify Purpose',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (selectedPurpose != null && !isOtherPurpose)
  Text(
    'Price: ₱${selectedPurpose!['price']}',
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      for (var field in formFields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildField(field),
                        ),
                      ElevatedButton(
                        onPressed:
                            isSubmitting ? null : showConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 20), // extra spacing sa bottom
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}
}