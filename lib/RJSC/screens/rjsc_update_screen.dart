// lib/RJSC/screens/rjsc_update_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rjsc_response_dto.dart';
import '../models/upload_file_model.dart';
import '../services/rjsc_service.dart';

class RjscUpdateScreen extends StatefulWidget {
  final RjscResponseDTO rjsc;

  const RjscUpdateScreen({super.key, required this.rjsc});

  @override
  State<RjscUpdateScreen> createState() => _RjscUpdateScreenState();
}

class _RjscUpdateScreenState extends State<RjscUpdateScreen> {
  // ============ Theme Colors ============
  static const Color _primaryGreen = Color(0xFF0B5D36);
  static const Color _lightGreenBg = Color(0xFFECFDF5);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  // ============ State ============
  int _currentStep = 1;
  bool _isSubmitting = false;

  // Step 1
  String _selectedComplianceService = 'Form IX (Director Details)';
  final List<String> _complianceOptions = [
    'Form IX (Director Details)',
    'Form XII (Particulars of Directors/Members)',
    'Director Change',
    'Share Transfer',
    'Address Change',
    'Increase of Capital',
  ];

  // Step 2
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _registrationNoController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedYear;
  final List<String> _yearOptions = [
    '2023-2024',
    '2024-2025',
    '2025-2026',
    '2026-2027',
    '2027-2028',
    '2028-2029',
    '2029-2030',
  ];

  // Step 3
  UploadFileModel? _memorandumFile;
  UploadFileModel? _boardResolutionFile;
  UploadFileModel? _otherDocumentsFile;

  // ============ Existing Documents (already in backend) ============
  List<String> _existingDocuments = [];

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  // ============ Pre-fill from existing RJSC ============
  void _prefillData() {
    final r = widget.rjsc;

    // Step 1
    if (_complianceOptions.contains(r.compilenceService)) {
      _selectedComplianceService = r.compilenceService;
    } else {
      // Fallback: add it to list so dropdown matches
      _selectedComplianceService = _complianceOptions.first;
    }

    // Step 2
    _companyNameController.text = r.companyName;
    _registrationNoController.text = r.registrationNo;
    _emailController.text = r.email;

    // Year → convert to "2025-2026" format
    final year = r.year.year;
    _selectedYear = '$year-${year + 1}';
    if (!_yearOptions.contains(_selectedYear)) {
      _selectedYear = _yearOptions.first;
    }

    // Step 3 - existing documents
    _existingDocuments = List<String>.from(r.documents);
  }

// lib/RJSC/screens/rjsc_update_screen.dart

// ✅ UPDATED: Multi-device compatible picker
Future<UploadFileModel?> _pickFile({bool allowMultipleTypes = false}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowMultipleTypes
          ? ['pdf', 'jpg', 'jpeg', 'png']
          : ['pdf'],
      // ✅ CRITICAL: always withData: true
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;

    debugPrint('📁 Picked: ${picked.name}');
    debugPrint('   bytes=${picked.bytes?.length}');
    debugPrint('   path=${picked.path}');

    final hasBytes = picked.bytes != null && picked.bytes!.isNotEmpty;
    final hasPath = picked.path != null && picked.path!.isNotEmpty;

    if (!hasBytes && !hasPath) {
      _showSnack('Selected file has no data', isError: true);
      return null;
    }

    return UploadFileModel.fromPlatformFile(picked);
  } catch (e) {
    debugPrint('❌ File pick error: $e');
    _showSnack('Could not pick file: $e', isError: true);
  }
  return null;
}
// lib/RJSC/screens/rjsc_update_screen.dart

Future<void> _submitUpdate() async {
  setState(() => _isSubmitting = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty) {
      _showSnack('User not logged in', isError: true);
      setState(() => _isSubmitting = false);
      return;
    }

    if (widget.rjsc.id == null) {
      _showSnack('Invalid RJSC id', isError: true);
      setState(() => _isSubmitting = false);
      return;
    }

    // ✅ New files
    final List<UploadFileModel> newDocs = [];
    if (_memorandumFile != null) newDocs.add(_memorandumFile!);
    if (_boardResolutionFile != null) newDocs.add(_boardResolutionFile!);
    if (_otherDocumentsFile != null) newDocs.add(_otherDocumentsFile!);

    debugPrint('📦 New files: ${newDocs.length}');
    for (final d in newDocs) {
      debugPrint(
          '   - ${d.fileName} | bytes=${d.bytes?.length} | path=${d.path}');
    }

    // Year → ISO
    String? yearIso;
    if (_selectedYear != null && _selectedYear!.contains('-')) {
      final startYear = _selectedYear!.split('-').first;
      yearIso = '${startYear}-01-01T00:00:00Z';
    }

    final result = await RjscService.updateRjsc(
      id: widget.rjsc.id!,
      userId: userId,
      compilenceService: _selectedComplianceService,
      registrationNo: _registrationNoController.text.trim(),
      email: _emailController.text.trim(),
      companyName: _companyNameController.text.trim(),
      year: yearIso,
      attachmentsId: _existingDocuments, // ✅ existing kept
      documents: newDocs,                // ✅ new uploaded
    );

    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      _showSnack('RJSC updated successfully');
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnack(result['message']?.toString() ?? 'Update failed',
          isError: true);
    }
  } catch (e) {
    setState(() => _isSubmitting = false);
    _showSnack('Error: $e', isError: true);
  }
}
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : _primaryGreen,
      ),
    );
  }

  // ============ Validation ============
  bool _validateStep1() => _selectedComplianceService.isNotEmpty;

  bool _validateStep2() {
    if (_companyNameController.text.trim().isEmpty) {
      _showSnack('Company name is required', isError: true);
      return false;
    }
    if (_registrationNoController.text.trim().isEmpty) {
      _showSnack('RJSC Registration No. is required', isError: true);
      return false;
    }
    if (_selectedYear == null) {
      _showSnack('Financial Year is required', isError: true);
      return false;
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      _showSnack('Valid email is required', isError: true);
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    // For update, documents can be empty (existing ones kept)
    return true;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _registrationNoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Update RJSC',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildFormStep(),
    );
  }

  // ============ Form Container ============
  Widget _buildFormStep() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                  const SizedBox(height: 24),
                  _buildNavButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============ Step Indicator ============
  Widget _buildStepIndicator() {
    final steps = ['Compliance', 'Company', 'Documents'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final stepNum = i + 1;
          final isActive = stepNum <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? _primaryGreen : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? _primaryGreen : _borderColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$stepNum',
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : _textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? _primaryGreen : _borderColor,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ============ STEP 1 ============
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('1', 'SELECT COMPLIANCE TYPE'),
        const SizedBox(height: 16),
        Text(
          'Select Compliance Service',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 12),
        ..._complianceOptions.map((option) {
          final isSelected = _selectedComplianceService == option;
          return InkWell(
            onTap: () => setState(() => _selectedComplianceService = option),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _primaryGreen : _textGrey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: _primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _textDark,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ============ STEP 2 ============
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('2', 'COMPANY INFORMATION'),
        const SizedBox(height: 16),
        _labelText('Company Name'),
        _textField(
          controller: _companyNameController,
          hint: 'Enter company name',
        ),
        const SizedBox(height: 16),
        _labelText('RJSC Registration No.'),
        _textField(
          controller: _registrationNoController,
          hint: 'Enter RJSC no.',
        ),
        const SizedBox(height: 16),
        _labelText('Financial Year'),
        _dropdown(
          value: _selectedYear,
          hint: 'Select year',
          items: _yearOptions,
          onChanged: (v) => setState(() => _selectedYear = v),
        ),
        const SizedBox(height: 16),
        _labelText('Email'),
        _textField(
          controller: _emailController,
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  // ============ STEP 3 ============
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('3', 'UPLOAD DOCUMENTS'),
        const SizedBox(height: 8),

        // Existing documents
        if (_existingDocuments.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _lightGreenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _primaryGreen.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_outlined,
                        color: _primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_existingDocuments.length} existing document(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'These will be kept unless you replace them.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          'Add new documents (optional)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 10),
        _uploadTile(
          title: 'Memorandum & Articles',
          subtitle: 'Upload PDF',
          file: _memorandumFile,
          onPick: () async {
            final f = await _pickFile();
            if (f != null) setState(() => _memorandumFile = f);
          },
          onRemove: () => setState(() => _memorandumFile = null),
        ),
        const SizedBox(height: 12),
        _uploadTile(
          title: 'Board Resolution',
          subtitle: 'Upload PDF',
          file: _boardResolutionFile,
          onPick: () async {
            final f = await _pickFile();
            if (f != null) setState(() => _boardResolutionFile = f);
          },
          onRemove: () => setState(() => _boardResolutionFile = null),
        ),
        const SizedBox(height: 12),
        _uploadTile(
          title: 'Other Documents',
          subtitle: 'Upload PDF/JPG/PNG',
          file: _otherDocumentsFile,
          onPick: () async {
            final f = await _pickFile(allowMultipleTypes: true);
            if (f != null) setState(() => _otherDocumentsFile = f);
          },
          onRemove: () => setState(() => _otherDocumentsFile = null),
        ),
      ],
    );
  }

  // ============ Nav Buttons ============
  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Back',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_currentStep == 1) {
                      if (_validateStep1()) {
                        setState(() => _currentStep = 2);
                      }
                    } else if (_currentStep == 2) {
                      if (_validateStep2()) {
                        setState(() => _currentStep = 3);
                      }
                    } else if (_currentStep == 3) {
                      if (_validateStep3()) {
                        await _submitUpdate();
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _currentStep == 3 ? 'Update' : 'Next',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // ============ Helpers ============
  Widget _sectionHeader(String num, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _textDark,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _labelText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _textGrey, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
      hint: Text(hint,
          style: GoogleFonts.inter(color: _textGrey, fontSize: 13)),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.inter(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _uploadTile({
    required String title,
    required String subtitle,
    required UploadFileModel? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final isUploaded = file != null;
    return InkWell(
      onTap: isUploaded ? null : onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUploaded ? _lightGreenBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUploaded ? _primaryGreen : _borderColor,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _lightGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined,
                  color: _primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded
                        ? (file.fileName.length > 30
                            ? '${file.fileName.substring(0, 30)}...'
                            : file.fileName)
                        : subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _textGrey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isUploaded ? onRemove : onPick,
              icon: Icon(
                isUploaded ? Icons.close : Icons.upload_outlined,
                color: isUploaded ? Colors.red : _primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}