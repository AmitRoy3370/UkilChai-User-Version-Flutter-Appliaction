// lib/CompanyPages/company_registration_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechai/Auth/AuthService.dart';
import '../CompanyPages/company_information.dart';
import '../CompanyPages/company_service.dart';
import '../CompanyPages/capital_service.dart';
import '../CompanyPages/capital.dart';
import '../DirectorsPages/director_service.dart';
import '../DirectorsPages/director_response.dart';
import '../ShareholderPages/shareholder_service.dart';
import '../ShareholderPages/shareholder.dart';
import '../ShareholderPages/shareholder_response.dart';
import '../CompanyPages/subscription.dart';
import '../CompanyPages/subscription_service.dart';
import '../CompanyPages/company_contact.dart';
import '../CompanyPages/company_contact_service.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class CompanyRegistrationScreen extends StatefulWidget {
  final String? userId;

  const CompanyRegistrationScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState
    extends State<CompanyRegistrationScreen> {
  // ==================== CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _authorizedController = TextEditingController();

  // ==================== SERVICES ====================
  final CompanyService _companyService = CompanyService();
  final DirectorService _directorService = DirectorService();
  final ShareholderService _shareholderService = ShareholderService();
  final CapitalService _capitalService = CapitalService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CompanyContactService _companyContactService = CompanyContactService();

  // ==================== STATE ====================
  bool _isLoading = false;
  bool _isSubmitting = false;
  int _currentStep = 0;
  String? _submitMessage;
  bool _isSubmitSuccess = false;
  String? _userId;

  // ==================== COMPANY DATA ====================
  String? _companyId;

  // ==================== DIRECTORS ====================
  List<DirectorResponse> _availableDirectors = [];
  List<String> _selectedDirectors = [];
  bool _isLoadingDirectors = false;
  String? _directorsError;

  // ==================== SHAREHOLDERS ====================
  List<ShareholderResponse> _availableShareholders = [];
  List<ShareholderResponse> _selectedShareholders = [];
  bool _isLoadingShareholders = false;
  String? _shareholdersError;

  // ==================== DOCUMENTS ====================
  List<PlatformFile> _documents = [];
  bool _hasDocuments = false;

  // ==================== CAPITAL ====================
  Capital? _capital;
  bool _hasCapital = false;

  // ==================== SUBSCRIPTION ====================
  Subscription? _subscription;
  bool _hasSubscription = false;
  PlatformFile? _signatureFile;
  bool _hasSignature = false;

  // ==================== COMPANY CONTACT ====================
  CompanyContact? _companyContact;
  bool _hasCompanyContact = false;

  // ==================== STEP 1: COMPANY INFORMATION ====================
  String? _selectedType;
  String? _selectedNatureOfBusiness;
  String? _selectedCategory;

  final List<String> _companyTypes = [
    'Private Limited',
    'Public Limited',
    'Sole Proprietorship',
    'Partnership',
    'LLP',
    'Others',
  ];

  final List<String> _natureOfBusinessOptions = [
    'IT Consulting',
    'Software Development',
    'Manufacturing',
    'Trading',
    'Service',
    'Education',
    'Healthcare',
    'Construction',
    'Real Estate',
    'Others',
  ];

  final List<String> _categoryOptions = [
    'Large',
    'Medium',
    'Small',
    'Micro',
  ];

  bool _hasAgreedToTerms = false;

  // ==================== REVIEW DATA ====================
  Map<String, dynamic> get _reviewData => {
        'Company Name': _companyNameController.text.isEmpty
            ? 'Not provided'
            : _companyNameController.text,
        'Company Type': _selectedType ?? 'Not selected',
        'Nature of Business': _selectedNatureOfBusiness ?? 'Not selected',
        'Category': _selectedCategory ?? 'Not selected',
        'Authorized Person': _authorizedController.text.isEmpty
            ? 'Not provided'
            : _authorizedController.text,
        'Directors': _selectedDirectors.isNotEmpty
            ? _selectedDirectors.length.toString()
            : 'None selected',
        'Shareholders': _selectedShareholders.isNotEmpty
            ? _selectedShareholders.length.toString()
            : 'None selected',
        'Documents': _documents.isNotEmpty
            ? _documents.length.toString()
            : 'None uploaded',
        'Capital': _capital != null
            ? 'Authorized Capital: ৳${_capital!.authorizedCapital.toStringAsFixed(2)}'
            : 'Not added',
        'Subscription': _subscription != null
            ? 'Subscriber: ${_subscription!.subscriberName} (${_subscription!.numberOfShare} shares)'
            : 'Not added',
        'Company Contact': _companyContact != null
            ? 'Contact: ${_companyContact!.contactPersonName}'
            : 'Not added',
      };

  @override
  void initState() {
    super.initState();
    print('🟢 ============================================');
    print('🟢 INIT STATE - CompanyRegistrationScreen');
    print('🟢 ============================================');
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('🔄 INITIALIZING DATA...');
    print('🔄 ============================================');
    await _loadUserId();
    await _loadDirectors();
    await _loadShareholders();
    print('✅ DATA INITIALIZATION COMPLETE');
    print('✅ ============================================');
  }

  // ✅ Load userId from SharedPreferences
  Future<void> _loadUserId() async {
    print('🔍 LOADING USER ID...');
    print('🔍 ============================================');
    try {
      String? userId;
      
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      print('🔍 Source 1 - SharedPreferences userId: "$userId"');
      
      if (userId == null || userId.isEmpty) {
        userId = widget.userId;
        print('🔍 Source 2 - Widget userId: "$userId"');
      }
      
      if (userId == null || userId.isEmpty) {
        userId = await AuthService.getUserId();
        print('🔍 Source 3 - AuthService userId: "$userId"');
      }
      
      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
        await prefs.setString('userId', userId);
        await AuthService.saveUserId(userId);
        print('✅ User ID loaded successfully: "$_userId"');
        print('✅ ============================================');
      } else {
        print('⚠️ No user ID found in any source');
        print('⚠️ ============================================');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to register a company'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
      print('❌ ============================================');
    }
  }

  @override
  void dispose() {
    print('🗑️ DISPOSING - CompanyRegistrationScreen');
    print('🗑️ ============================================');
    _companyNameController.dispose();
    _authorizedController.dispose();
    super.dispose();
  }

  // ==================== LOAD DIRECTORS ====================
  Future<void> _loadDirectors() async {
    print('🔄 LOADING DIRECTORS...');
    print('🔄 ============================================');
    setState(() {
      _isLoadingDirectors = true;
      _directorsError = null;
    });

    try {
      final directors = await _directorService.getAllDirectors();
      print('📊 Directors loaded: ${directors.length}');
      setState(() {
        _availableDirectors = directors.where((d) => d.id != null && d.id!.isNotEmpty).toList();
        _isLoadingDirectors = false;
      });
      print('✅ Directors loaded successfully');
      print('✅ ============================================');
    } catch (e) {
      print('❌ Error loading directors: $e');
      print('❌ ============================================');
      setState(() {
        _directorsError = e.toString();
        _isLoadingDirectors = false;
      });
    }
  }

  // ==================== LOAD SHAREHOLDERS ====================
  Future<void> _loadShareholders() async {
    print('🔄 LOADING SHAREHOLDERS...');
    print('🔄 ============================================');
    setState(() {
      _isLoadingShareholders = true;
      _shareholdersError = null;
    });

    try {
      final shareholders = await _shareholderService.getAllShareholders();
      print('📊 Shareholders loaded: ${shareholders.length}');
      setState(() {
        _availableShareholders = shareholders;
        _isLoadingShareholders = false;
      });
      print('✅ Shareholders loaded successfully');
      print('✅ ============================================');
    } catch (e) {
      print('❌ Error loading shareholders: $e');
      print('❌ ============================================');
      setState(() {
        _shareholdersError = e.toString();
        _isLoadingShareholders = false;
      });
    }
  }

  // ==================== PICK DOCUMENTS ====================
  Future<void> _pickDocuments() async {
    print('📎 PICKING DOCUMENTS...');
    print('📎 ============================================');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        print('📎 Documents selected: ${result.files.length}');
        setState(() {
          _documents.addAll(result.files);
          _hasDocuments = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} document(s) selected'),
            backgroundColor: Colors.green,
          ),
        );
        print('✅ Documents picked successfully');
        print('✅ ============================================');
      } else {
        print('ℹ️ No documents selected');
        print('ℹ️ ============================================');
      }
    } catch (e) {
      print('❌ Error picking documents: $e');
      print('❌ ============================================');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking documents: $e')),
      );
    }
  }

  // ==================== REMOVE DOCUMENT ====================
  void _removeDocument(int index) {
    print('🗑️ Removing document at index: $index');
    setState(() {
      _documents.removeAt(index);
      if (_documents.isEmpty) {
        _hasDocuments = false;
      }
    });
    print('✅ Document removed');
    print('✅ ============================================');
  }

  // ==================== ADD CAPITAL ====================
  void _showAddCapitalDialog() {
    print('💰 Opening Add Capital Dialog');
    print('💰 ============================================');
    final authorizedController = TextEditingController();
    final totalShareController = TextEditingController();
    final numberOfShareController = TextEditingController();
    final shareValueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Capital Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: authorizedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Authorized Capital (BDT)',
                  hintText: 'Enter authorized capital',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: totalShareController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Shares',
                  hintText: 'Enter total shares',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: numberOfShareController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Shares',
                  hintText: 'Enter number of shares',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: shareValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Share Value (Per Share)',
                  hintText: 'Enter share value',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authorized = double.tryParse(authorizedController.text);
              final totalShare = int.tryParse(totalShareController.text);
              final numberOfShare = int.tryParse(numberOfShareController.text);
              final shareValue = double.tryParse(shareValueController.text);

              print('💰 Capital values:');
              print('   Authorized: $authorized');
              print('   TotalShare: $totalShare');
              print('   NumberOfShare: $numberOfShare');
              print('   ShareValue: $shareValue');

              if (authorized == null || totalShare == null || numberOfShare == null || shareValue == null) {
                print('❌ Invalid capital values - showing error');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _capital = Capital(
                  companyId: '',
                  authorizedCapital: authorized,
                  totalShare: totalShare,
                  numberOfShare: numberOfShare,
                  shareValue: shareValue,
                );
                _hasCapital = true;
                print('✅ Capital added: ${_capital!.toJson()}');
                print('✅ ============================================');
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Capital'),
          ),
        ],
      ),
    );
  }

  // ==================== ADD SUBSCRIPTION ====================
  void _showAddSubscriptionDialog() {
    print('📝 Opening Add Subscription Dialog');
    print('📝 ============================================');
    
    final subscriberNameController = TextEditingController();
    final numberOfShareController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Subscription Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subscriberNameController,
                    decoration: const InputDecoration(
                      labelText: 'Subscriber Name *',
                      hintText: 'Enter subscriber name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberOfShareController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Shares *',
                      hintText: 'Enter number of shares',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            print('📎 Picking signature file...');
                            try {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                                withData: kIsWeb,
                              );

                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                print('📎 Signature file selected: ${file.name}');
                                setDialogState(() {
                                  _signatureFile = file;
                                  _hasSignature = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Signature: ${file.name} selected'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('❌ Error picking signature: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(_hasSignature ? 'Change Signature' : 'Upload Signature'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasSignature ? Colors.orange : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_hasSignature)
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: null,
                        ),
                    ],
                  ),
                  if (_hasSignature)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _signatureFile!.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _signatureFile = null;
                    _hasSignature = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final subscriberName = subscriberNameController.text.trim();
                  final numberOfShare = int.tryParse(numberOfShareController.text.trim());

                  print('📝 Subscription values:');
                  print('   Subscriber Name: "$subscriberName"');
                  print('   Number of Shares: $numberOfShare');
                  print('   Signature: ${_hasSignature ? _signatureFile!.name : "None"}');

                  if (subscriberName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter subscriber name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (numberOfShare == null || numberOfShare <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number of shares'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _subscription = Subscription(
                      companyId: _companyId ?? '',
                      subscriberName: subscriberName,
                      numberOfShare: numberOfShare,
                    );
                    _hasSubscription = true;
                    print('✅ Subscription added: ${_subscription!.toJson()}');
                    print('✅ ============================================');
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Subscription'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== ADD COMPANY CONTACT ====================
  void _showAddCompanyContactDialog() {
    print('📞 Opening Add Company Contact Dialog');
    print('📞 ============================================');
    
    final contactPersonNameController = TextEditingController();
    final contactPersonMobileController = TextEditingController();
    final contactPersonEmailController = TextEditingController();
    String? selectedHowDidHear;
    final anyOtherMessageController = TextEditingController();

    final List<String> howDidHearOptions = [
      'Search Engine',
      'Social Media',
      'Friend/Colleague',
      'Advertisement',
      'Email',
      'Newsletter',
      'Event',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Company Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contactPersonNameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person Name *',
                  hintText: 'Enter contact person name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPersonMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: 'Enter mobile number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPersonEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'How Did You Hear About Us? *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                value: selectedHowDidHear,
                items: howDidHearOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  selectedHowDidHear = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: anyOtherMessageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Any Other Message',
                  hintText: 'Enter any additional message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = contactPersonNameController.text.trim();
              final mobile = contactPersonMobileController.text.trim();
              final email = contactPersonEmailController.text.trim();
              final message = anyOtherMessageController.text.trim();

              print('📞 Company Contact values:');
              print('   Name: "$name"');
              print('   Mobile: "$mobile"');
              print('   Email: "$email"');
              print('   How Did Hear: "$selectedHowDidHear"');
              print('   Message: "$message"');

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter contact person name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (mobile.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter mobile number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (selectedHowDidHear == null || selectedHowDidHear!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select how you heard about us'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _companyContact = CompanyContact(
                  contactPersonName: name,
                  contactPersonMobile: mobile,
                  contactPersonEmail: email,
                  howDidHear: selectedHowDidHear!,
                  anyOtherMessage: message.isNotEmpty ? message : null,
                  companyId: _companyId ?? '',
                );
                _hasCompanyContact = true;
                print('✅ Company Contact added: ${_companyContact!.toJson()}');
                print('✅ ============================================');
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  // ==================== UPDATE SHAREHOLDER PERCENTAGES ====================
  Future<void> _updateShareholderPercentages({
    required String companyId,
    required String userId,
    required List<ShareholderResponse> shareholders,
  }) async {
    print('📊 ============================================');
    print('📊 UPDATING SHAREHOLDER PERCENTAGES...');
    print('📊 ============================================');
    
    if (shareholders.isEmpty) {
      print('⏭️ No shareholders to update');
      return;
    }

    try {
      for (var holder in shareholders) {
        if (holder.id == null || holder.id!.isEmpty) {
          print('⚠️ Skipping shareholder with no ID');
          continue;
        }
        
        // Get the percentage from the holder's sharePercentage map
        double percentage = 0.0;
        if (holder.sharePercentage != null && 
            holder.sharePercentage!.isNotEmpty) {
          final percentages = holder.sharePercentage!.values.first;
          if (percentages.isNotEmpty) {
            percentage = percentages.first;
          }
        }
        
        print('📊 Processing shareholder: ${holder.id} (${percentage}%)');
        
        try {
          final shareholderResponse = await _shareholderService.getShareholderById(holder.id);
          
          if (shareholderResponse.id != null) {
            Map<String, List<double>> sharePercentage = {};
            
            if (shareholderResponse.sharePercentage != null && 
                shareholderResponse.sharePercentage!.isNotEmpty) {
              for (var entry in shareholderResponse.sharePercentage!.entries) {
                String key = entry.key;
                List<double> values = entry.value;
                if (values is List) {
                  sharePercentage[key] = List<double>.from(values);
                } else {
                  sharePercentage[key] = [];
                }
              }
            }
            
            if (sharePercentage.containsKey(companyId)) {
              final existingPercentages = sharePercentage[companyId] ?? [];
              if (!existingPercentages.contains(percentage)) {
                existingPercentages.add(percentage);
                sharePercentage[companyId] = existingPercentages;
                print('📊 Appended ${percentage}% to existing company entry');
              } else {
                print('📊 Percentage ${percentage}% already exists for this company');
              }
            } else {
              sharePercentage[companyId] = [percentage];
              print('📊 Added new company entry with ${percentage}%');
            }
            
            print('📊 Updated sharePercentage: $sharePercentage');
            
            final updatedShareholder = Shareholder(
              id: shareholderResponse.id,
              userId: userId,
              nid: shareholderResponse.nid,
              tin: shareholderResponse.tin,
              sharePercentage: sharePercentage,
            );
            
            print('📤 Updated Shareholder data: ${updatedShareholder.toJson()}');
            
            await _shareholderService.updateShareholder(
              id: shareholderResponse.id!,
              shareholder: updatedShareholder,
              userId: userId,
              nidFile: null,
              tinFile: null,
              removeNid: false,
              removeTin: false,
            );
            
            print('✅ Shareholder ${holder.id} updated with company $companyId at ${percentage}%');
          } else {
            print('⚠️ Shareholder ${holder.id} has no ID, skipping');
          }
        } catch (e) {
          print('⚠️ Error updating shareholder ${holder.id}: $e');
        }
      }
      
      print('✅ All shareholder percentages updated successfully');
      print('📊 ============================================');
    } catch (e) {
      print('❌ Error updating shareholder percentages: $e');
      print('❌ ============================================');
    }
  }

  // ==================== SUBMIT COMPANY ====================
  Future<void> _submitCompany() async {
    print('🚀 ============================================');
    print('🚀 SUBMITTING COMPANY...');
    print('🚀 ============================================');
    
    print('📋 Step 1: Validating form data directly...');
    
    String? validationError;
    
    final companyName = _companyNameController.text.trim();
    if (companyName.isEmpty) {
      validationError = 'Please enter company name';
      print('❌ Validation failed: Company name is empty');
    }
    
    if (validationError == null && (_selectedType == null || _selectedType!.isEmpty)) {
      validationError = 'Please select company type';
      print('❌ Validation failed: Company type not selected');
    }
    
    if (validationError == null && (_selectedNatureOfBusiness == null || _selectedNatureOfBusiness!.isEmpty)) {
      validationError = 'Please select nature of business';
      print('❌ Validation failed: Nature of business not selected');
    }
    
    if (validationError == null && (_selectedCategory == null || _selectedCategory!.isEmpty)) {
      validationError = 'Please select business category';
      print('❌ Validation failed: Business category not selected');
    }
    
    if (validationError != null) {
      print('❌ Form validation failed: $validationError');
      print('❌ ============================================');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    print('✅ All validations passed');

    print('📋 Step 2: Checking terms agreement...');
    print('📋 _hasAgreedToTerms = $_hasAgreedToTerms');
    
    if (!_hasAgreedToTerms) {
      print('❌ User did not agree to terms');
      print('❌ ============================================');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that all information is accurate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    print('✅ User agreed to terms');

    print('📋 Step 3: Getting User ID...');
    print('📋 ============================================');
    String? userId;
    
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    print('📋 Source 1 - SharedPreferences userId: "$userId"');
    
    if (userId == null || userId.isEmpty) {
      userId = widget.userId;
      print('📋 Source 2 - Widget userId: "$userId"');
    }
    
    if (userId == null || userId.isEmpty) {
      userId = _userId;
      print('📋 Source 3 - State _userId: "$userId"');
    }
    
    if (userId == null || userId.isEmpty) {
      userId = await AuthService.getUserId();
      print('📋 Source 4 - AuthService userId: "$userId"');
    }
    
    if (userId == null || userId.isEmpty) {
      print('❌❌❌ CRITICAL: No userId found from any source!');
      print('❌❌❌ ============================================');
      setState(() {
        _isSubmitSuccess = false;
        _submitMessage = '❌ Error: User not logged in. Please login again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please login again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('✅ Final userId: "$userId"');

    setState(() {
      _userId = userId;
    });
    await prefs.setString('userId', userId!);
    await AuthService.saveUserId(userId!);
    print('✅ UserId saved to SharedPreferences');

    String? creatorDirectorId = prefs.getString('directorId');
    print('📋 Creator DirectorId: "$creatorDirectorId"');

    print('📋 Ensuring unique values using Set...');
    
    Set<String> directorsSet = {};
    
    if (creatorDirectorId != null && creatorDirectorId.isNotEmpty) {
      directorsSet.add(creatorDirectorId);
      print('📋 Added creator director: "$creatorDirectorId"');
    }
    
    for (String dirId in _selectedDirectors) {
      if (dirId.isNotEmpty) {
        directorsSet.add(dirId);
        print('📋 Added director: "$dirId"');
      }
    }
    
    final uniqueDirectors = directorsSet.toList();
    print('📋 Total unique directors: ${uniqueDirectors.length}');

    Set<String> shareholdersSet = {};
    
    for (var holder in _selectedShareholders) {
      if (holder.id != null && holder.id!.isNotEmpty) {
        shareholdersSet.add(holder.id!);
        // Get percentage from sharePercentage map
        double percentage = 0.0;
        if (holder.sharePercentage != null && holder.sharePercentage!.isNotEmpty) {
          final percentages = holder.sharePercentage!.values.first;
          if (percentages.isNotEmpty) {
            percentage = percentages.first;
          }
        }
        print('📋 Added shareholder: "${holder.id}" ($percentage%)');
      }
    }
    
    final uniqueShareholders = shareholdersSet.toList();
    print('📋 Total unique shareholders: ${uniqueShareholders.length}');

    print('📊 ============================================');
    print('📊 Company Data:');
    print('📊   UserId: "$userId"');
    print('📊   Name: "$companyName"');
    print('📊   Type: "${_selectedType ?? ''}"');
    print('📊   Nature: "${_selectedNatureOfBusiness ?? ''}"');
    print('📊   Category: "${_selectedCategory ?? ''}"');
    print('📊   Directors: ${uniqueDirectors.length} (unique)');
    print('📊   Shareholders: ${uniqueShareholders.length} (unique)');
    print('📊   Documents: ${_documents.length}');
    print('📊   Capital: ${_capital != null ? 'Will be added after company creation' : 'No capital'}');
    print('📊   Subscription: ${_subscription != null ? 'Will be added after company creation' : 'No subscription'}');
    print('📊   Company Contact: ${_companyContact != null ? 'Will be added after company creation' : 'No contact'}');
    print('📊 ============================================');

    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
      _isSubmitSuccess = false;
    });

    try {
      print('📋 Step 4: Building company object (with unique values from Set)...');
      
      final company = CompanyInformation(
        companyName: companyName,
        type: _selectedType ?? '',
        natureOfBusiness: _selectedNatureOfBusiness ?? '',
        category: _selectedCategory ?? '',
        officeRegistryId: null,
        authorized: _authorizedController.text.trim().isEmpty
            ? null
            : _authorizedController.text.trim(),
        directorsId: uniqueDirectors,
        shareHolders: uniqueShareholders,
        creatorId: userId,
        capital: [],
        documents: [],
      );

      print('📤 Company object created:');
      print('📤 ${company.toJson()}');

      print('📋 Step 5: Creating company via API...');
      print('📤 Calling createCompany with userId: "$userId"');
      
      final created = await _companyService.createCompany(
        company: company,
        userId: userId,
        files: null,
      );

      final newCompanyId = created.id;
      print('✅ Company created with ID: "$newCompanyId"');
      
      if (newCompanyId == null || newCompanyId.isEmpty) {
        print('❌ Company creation returned no ID');
        throw Exception("Company creation succeeded, but returned no valid ID.");
      }
      _companyId = newCompanyId;

      Set<String> existingDirectorsSet = {};
      try {
        final companyResponse = await _companyService.getCompanyById(newCompanyId);
        if (companyResponse.directorsId != null) {
          existingDirectorsSet.addAll(companyResponse.directorsId!);
          print('📋 Existing directors in company: ${existingDirectorsSet.length}');
        }
      } catch (e) {
        print('⚠️ Could not fetch existing directors: $e');
      }

      print('📋 Step 6: Adding directors (only if not already in company)...');
      int directorsAdded = 0;
      for (String dirId in uniqueDirectors) {
        if (!existingDirectorsSet.contains(dirId)) {
          if (dirId != creatorDirectorId) {
            print('   ➕ Adding director: "$dirId"');
            await _companyService.addDirectorToCompany(
              companyId: newCompanyId,
              directorId: dirId,
              userId: userId,
            );
            directorsAdded++;
            print('   ✅ Director "$dirId" added');
            existingDirectorsSet.add(dirId);
          } else {
            print('   ⏭️ Skipping creator director: "$dirId" (already added)');
          }
        } else {
          print('   ⏭️ Director "$dirId" already exists in company, skipping');
        }
      }
      print('📋 Directors added: $directorsAdded');

      Set<String> existingShareholdersSet = {};
      try {
        final companyResponse = await _companyService.getCompanyById(newCompanyId);
        if (companyResponse.shareHolders != null) {
          existingShareholdersSet.addAll(companyResponse.shareHolders!);
          print('📋 Existing shareholders in company: ${existingShareholdersSet.length}');
        }
      } catch (e) {
        print('⚠️ Could not fetch existing shareholders: $e');
      }

      print('📋 Step 7: Adding shareholders (only if not already in company)...');
      int shareholdersAdded = 0;
      for (String holderId in uniqueShareholders) {
        if (!existingShareholdersSet.contains(holderId)) {
          print('   ➕ Adding shareholder: "$holderId"');
          await _companyService.addShareholderToCompany(
            companyId: newCompanyId,
            shareholderId: holderId,
            userId: userId,
          );
          shareholdersAdded++;
          print('   ✅ Shareholder "$holderId" added');
          existingShareholdersSet.add(holderId);
        } else {
          print('   ⏭️ Shareholder "$holderId" already exists in company, skipping');
        }
      }
      print('📋 Shareholders added: $shareholdersAdded');

      // ✅ Update shareholder percentages
      if (_selectedShareholders.isNotEmpty) {
        print('📊 Step 7.5: Updating shareholder percentages...');
        await _updateShareholderPercentages(
          companyId: newCompanyId,
          userId: userId,
          shareholders: _selectedShareholders,
        );
      }

      // ✅ 8. Add Capital AFTER company creation (if provided)
      String? capitalId;
      if (_capital != null) {
        print('📋 Step 8: Adding Capital to company (POST-creation)...');
        final capital = _capital!.copyWith(companyId: newCompanyId);
        print('   💰 Capital data: ${capital.toJson()}');
        final addedCapital = await _capitalService.addCapital(
          capital: capital,
          userId: userId,
        );
        capitalId = addedCapital.id;
        print('✅ Capital added successfully with ID: "$capitalId"');
      } else {
        print('⏭️ No capital to add');
      }

      // ✅ 9. Add Subscription AFTER company creation (if provided)
      String? subscriptionId;
      if (_subscription != null) {
        print('📋 Step 9: Adding Subscription to company (POST-creation)...');
        final subscription = _subscription!.copyWith(companyId: newCompanyId);
        print('   📝 Subscription data: ${subscription.toJson()}');
        try {
          final addedSubscription = await _subscriptionService.addSubscription(
            subscription: subscription,
            userId: userId,
            signatureFile: _signatureFile,
          );
          subscriptionId = addedSubscription.id;
          print('✅ Subscription added successfully with ID: "$subscriptionId"');
        } catch (e) {
          print('⚠️ Error adding subscription: $e');
        }
      } else {
        print('⏭️ No subscription to add');
      }

      // ✅ 10. Add Company Contact AFTER company creation (if provided)
      String? contactId;
      if (_companyContact != null) {
        print('📋 Step 10: Adding Company Contact to company (POST-creation)...');
        final contact = _companyContact!.copyWith(companyId: newCompanyId);
        print('   📞 Contact data: ${contact.toJson()}');
        try {
          final addedContact = await _companyContactService.addCompanyContact(
            contact: contact,
            userId: userId,
          );
          contactId = addedContact.id;
          print('✅ Company Contact added successfully with ID: "$contactId"');
        } catch (e) {
          print('⚠️ Error adding company contact: $e');
        }
      } else {
        print('⏭️ No company contact to add');
      }

      // ✅ 11. Update company with documents, capital, subscription, and contact
      final finalDirectorsList = existingDirectorsSet.toList();
      final finalShareholdersList = existingShareholdersSet.toList();
      
      print('📋 Final directors count: ${finalDirectorsList.length}');
      print('📋 Final shareholders count: ${finalShareholdersList.length}');

      final updatedCompany = CompanyInformation(
        companyName: companyName,
        type: _selectedType ?? '',
        natureOfBusiness: _selectedNatureOfBusiness ?? '',
        category: _selectedCategory ?? '',
        officeRegistryId: null,
        authorized: _authorizedController.text.trim().isEmpty
            ? null
            : _authorizedController.text.trim(),
        directorsId: finalDirectorsList,
        shareHolders: finalShareholdersList,
        creatorId: userId,
        capital: capitalId != null ? [capitalId] : [],
        documents: [],
      );

      if (_documents.isNotEmpty) {
        print('📋 Step 11: Adding ${_documents.length} documents...');
        await _companyService.updateCompany(
          id: newCompanyId,
          company: updatedCompany,
          userId: userId,
          files: _documents,
        );
        print('✅ Documents uploaded successfully!');
      } else if (capitalId != null || subscriptionId != null || contactId != null) {
        print('📋 Step 11: Updating company with additional data...');
        await _companyService.updateCompany(
          id: newCompanyId,
          company: updatedCompany,
          userId: userId,
          files: null,
        );
        print('✅ Company updated with additional data!');
      } else {
        print('⏭️ No documents or additional data to update');
      }

      print('✅✅✅ ============================================');
      print('✅✅✅ COMPANY REGISTRATION COMPLETE!');
      print('✅✅✅ Company ID: "$newCompanyId"');
      if (capitalId != null) {
        print('✅✅✅ Capital ID: "$capitalId"');
      }
      if (subscriptionId != null) {
        print('✅✅✅ Subscription ID: "$subscriptionId"');
      }
      if (contactId != null) {
        print('✅✅✅ Company Contact ID: "$contactId"');
      }
      print('✅✅✅ Documents: ${_documents.length}');
      print('✅✅✅ Total Directors: ${finalDirectorsList.length}');
      print('✅✅✅ Total Shareholders: ${finalShareholdersList.length}');
      print('✅✅✅ ============================================');

      setState(() {
        _isSubmitSuccess = true;
        _submitMessage = '✅ Company created and configured successfully!\nCompany ID: $newCompanyId';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Company created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _showSuccessDialog(newCompanyId);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      print('❌❌❌ ============================================');
      print('❌❌❌ ERROR in company registration process: $e');
      print('❌❌❌ Stack trace: ${StackTrace.current}');
      print('❌❌❌ ============================================');
      setState(() {
        _isSubmitSuccess = false;
        _submitMessage = '❌ Error: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
      print('🏁 Submission process completed');
      print('🏁 ============================================');
    }
  }

  // ==================== SUCCESS DIALOG ====================
  void _showSuccessDialog(String? companyId) {
    print('🎉 Showing success dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text(
              'Success!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your company has been registered successfully.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Name: ${_companyNameController.text}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'ID: ${companyId ?? 'N/A'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Type: ${_selectedType ?? 'N/A'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (_capital != null)
                    Text(
                      'Authorized Capital: ৳${_capital!.authorizedCapital.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  Text(
                    'Directors: ${_selectedDirectors.length + 1}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Shareholders: ${_selectedShareholders.length}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Documents: ${_documents.length}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (_subscription != null)
                    Text(
                      'Subscriber: ${_subscription!.subscriberName} (${_subscription!.numberOfShare} shares)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_companyContact != null)
                    Text(
                      'Contact: ${_companyContact!.contactPersonName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We will review your information and contact you soon.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD STEPS ====================
  List<Step> _buildSteps() {
    print('🏗️ Building steps...');
    return [
      _buildStep(
        title: 'Company Information',
        subtitle: 'Basic company details',
        content: _buildCompanyInfoStep(),
      ),
      _buildStep(
        title: 'Directors',
        subtitle: 'Add company directors',
        content: _buildDirectorsStep(),
      ),
      _buildStep(
        title: 'Shareholders',
        subtitle: 'Add company shareholders',
        content: _buildShareholdersStep(),
      ),
      _buildStep(
        title: 'Documents',
        subtitle: 'Upload required documents',
        content: _buildDocumentsStep(),
      ),
      _buildStep(
        title: 'Capital',
        subtitle: 'Add capital details',
        content: _buildCapitalStep(),
      ),
      _buildStep(
        title: 'Subscription',
        subtitle: 'Add subscription details',
        content: _buildSubscriptionStep(),
      ),
      _buildStep(
        title: 'Company Contact',
        subtitle: 'Add contact information',
        content: _buildCompanyContactStep(),
      ),
      _buildStep(
        title: 'Review',
        subtitle: 'Review all information',
        content: _buildReviewStep(),
      ),
    ];
  }

  Step _buildStep({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Step(
      title: Text(title),
      subtitle: Text(subtitle),
      content: content,
      isActive: true,
      state: _currentStep == _getStepIndex(title)
          ? StepState.editing
          : StepState.indexed,
    );
  }

  int _getStepIndex(String title) {
    const titles = [
      'Company Information',
      'Directors',
      'Shareholders',
      'Documents',
      'Capital',
      'Subscription',
      'Company Contact',
      'Review',
    ];
    return titles.indexOf(title);
  }

  // ==================== STEP 1: COMPANY INFORMATION ====================
  Widget _buildCompanyInfoStep() {
    print('🏗️ Building Company Info Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Proposed Name *',
            hintText: 'Enter company name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            print('🔍 Validating Company Name: "$value"');
            if (value == null || value.trim().isEmpty) {
              return 'Please enter company name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Company Type *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          value: _selectedType,
          items: _companyTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            print('🔍 Company Type changed: "$value"');
            setState(() {
              _selectedType = value;
            });
          },
          validator: (value) {
            print('🔍 Validating Company Type: "$value"');
            if (value == null || value.isEmpty) {
              return 'Please select company type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Nature of Business *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
          value: _selectedNatureOfBusiness,
          items: _natureOfBusinessOptions.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            print('🔍 Nature of Business changed: "$value"');
            setState(() {
              _selectedNatureOfBusiness = value;
            });
          },
          validator: (value) {
            print('🔍 Validating Nature of Business: "$value"');
            if (value == null || value.isEmpty) {
              return 'Please select nature of business';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Business Category *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          value: _selectedCategory,
          items: _categoryOptions.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            print('🔍 Business Category changed: "$value"');
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (value) {
            print('🔍 Validating Business Category: "$value"');
            if (value == null || value.isEmpty) {
              return 'Please select business category';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _authorizedController,
          decoration: const InputDecoration(
            labelText: 'Authorized Person',
            hintText: 'Enter authorized person name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 2: DIRECTORS ====================
  Widget _buildDirectorsStep() {
    print('🏗️ Building Directors Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Directors to Your Company',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select directors from the list below to add them to your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_isLoadingDirectors)
          const Center(child: CircularProgressIndicator())
        else if (_directorsError != null)
          Center(
            child: Column(
              children: [
                Text(
                  'Error: $_directorsError',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadDirectors,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_availableDirectors.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No directors available. Please register directors first.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._availableDirectors.map((director) {
            final isSelected = _selectedDirectors.contains(director.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.green : Colors.blue,
                  child: Text(
                    director.userName.isNotEmpty
                        ? director.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(director.userName),
                subtitle: Text(director.position),
                trailing: isSelected
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          print('🔍 Removing director: "${director.id}"');
                          setState(() {
                            _selectedDirectors.remove(director.id);
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          print('🔍 Adding director: "${director.id}"');
                          setState(() {
                            _selectedDirectors.add(director.id!);
                          });
                        },
                      ),
              ),
            );
          }).toList(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected: ${_selectedDirectors.length} director(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== STEP 3: SHAREHOLDERS ====================
  Widget _buildShareholdersStep() {
    print('🏗️ Building Shareholders Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Shareholders to Your Company',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select shareholders from the list below and specify their share percentage.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_isLoadingShareholders)
          const Center(child: CircularProgressIndicator())
        else if (_shareholdersError != null)
          Center(
            child: Column(
              children: [
                Text(
                  'Error: $_shareholdersError',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadShareholders,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_availableShareholders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No shareholders available. Please register shareholders first.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._availableShareholders.map((shareholder) {
            final existing = _selectedShareholders
                .where((e) => e.id == shareholder.id)
                .toList();
            final isSelected = existing.isNotEmpty;
            
            // Get percentage from sharePercentage map
            double sharePercentage = 0.0;
            if (isSelected) {
              if (existing.first.sharePercentage != null && 
                  existing.first.sharePercentage!.isNotEmpty) {
                final percentages = existing.first.sharePercentage!.values.first;
                if (percentages.isNotEmpty) {
                  sharePercentage = percentages.first;
                }
              }
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.green : Colors.orange,
                  child: Text(
                    shareholder.userName.isNotEmpty
                        ? shareholder.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(shareholder.userName),
                subtitle: isSelected
                    ? Text('Share: ${sharePercentage.toStringAsFixed(2)}%')
                    : const Text('Not added'),
                trailing: isSelected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              print('🔍 Editing shareholder: "${shareholder.id}"');
                              _showSharePercentageDialog(shareholder);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () {
                              print('🔍 Removing shareholder: "${shareholder.id}"');
                              setState(() {
                                _selectedShareholders
                                    .removeWhere((e) => e.id == shareholder.id);
                              });
                            },
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          print('🔍 Adding shareholder: "${shareholder.id}"');
                          _showSharePercentageDialog(shareholder);
                        },
                      ),
              ),
            );
          }).toList(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected: ${_selectedShareholders.length} shareholder(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SHARE PERCENTAGE DIALOG ====================
  void _showSharePercentageDialog(ShareholderResponse shareholder) {
    final controller = TextEditingController();
    final existing = _selectedShareholders
        .where((e) => e.id == shareholder.id)
        .toList();
    
    // Get existing percentage from sharePercentage map
    if (existing.isNotEmpty) {
      double currentPercentage = 0.0;
      if (existing.first.sharePercentage != null && 
          existing.first.sharePercentage!.isNotEmpty) {
        final percentages = existing.first.sharePercentage!.values.first;
        if (percentages.isNotEmpty) {
          currentPercentage = percentages.first;
        }
      }
      controller.text = currentPercentage.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Percentage for ${shareholder.userName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Share Percentage (%)',
            hintText: 'Enter percentage',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              print('🔍 Share percentage entered: $value%');
              if (value == null || value < 0 || value > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid percentage (0-100)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setState(() {
                _selectedShareholders.removeWhere(
                  (e) => e.id == shareholder.id,
                );
                
                // Create a copy of the shareholder with the percentage in the map
                final updatedShareholder = ShareholderResponse(
                  id: shareholder.id,
                  userId: shareholder.userId,
                  userName: shareholder.userName,
                  nid: shareholder.nid,
                  tin: shareholder.tin,
                  sharePercentage: {
                    // We'll use a temporary key, the actual companyId will be added later
                    'temp': [value],
                  },
                );
                
                _selectedShareholders.add(updatedShareholder);
                print('✅ Shareholder "${shareholder.id}" added with $value%');
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 4: DOCUMENTS ====================
  Widget _buildDocumentsStep() {
    print('🏗️ Building Documents Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Required Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload the following documents for your company registration.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Upload Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      ElevatedButton.icon(
                        onPressed: _pickDocuments,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildDocTypeChip('PDF', Colors.red),
                      _buildDocTypeChip('DOC', Colors.blue),
                      _buildDocTypeChip('DOCX', Colors.blue),
                      _buildDocTypeChip('PNG', Colors.green),
                      _buildDocTypeChip('JPG', Colors.orange),
                      _buildDocTypeChip('JPEG', Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_documents.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No documents uploaded yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add Files" to upload documents',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      const Text(
                        'Selected Documents:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._documents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        return _buildDocumentTile(
                          doc.name,
                          onRemove: () => _removeDocument(index),
                          fileSize: doc.size,
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported formats: PDF, DOC, DOCX, PNG, JPG',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${_documents.length} document(s) uploaded',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Document Type Chip
  Widget _buildDocTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ✅ Document Tile
  Widget _buildDocumentTile(
    String name, {
    VoidCallback? onRemove,
    int? fileSize,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize != null)
                  Text(
                    '${(fileSize / 1024).toStringAsFixed(2)} KB',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ==================== STEP 5: CAPITAL ====================
  Widget _buildCapitalStep() {
    print('🏗️ Building Capital Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Authorized Capital & Shares',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add capital details for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_capital != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Capital Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _showAddCapitalDialog,
                    ),
                  ],
                ),
                const Divider(),
                _buildCapitalRow('Authorized Capital', '৳${_capital!.authorizedCapital.toStringAsFixed(2)}'),
                _buildCapitalRow('Total Shares', _capital!.totalShare.toString()),
                _buildCapitalRow('Number of Shares', _capital!.numberOfShare.toString()),
                _buildCapitalRow('Share Value', '৳${_capital!.shareValue.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No capital added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddCapitalDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Capital'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================== STEP 6: SUBSCRIPTION ====================
  Widget _buildSubscriptionStep() {
    print('🏗️ Building Subscription Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add subscription information for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_subscription != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subscription Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _showAddSubscriptionDialog,
                    ),
                  ],
                ),
                const Divider(),
                _buildCapitalRow('Subscriber Name', _subscription!.subscriberName),
                _buildCapitalRow('Number of Shares', _subscription!.numberOfShare.toString()),
                _buildCapitalRow('Signature', _hasSignature ? _signatureFile!.name : 'No signature uploaded'),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No subscription added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddSubscriptionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================== STEP 7: COMPANY CONTACT ====================
  Widget _buildCompanyContactStep() {
    print('🏗️ Building Company Contact Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Contact Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add contact information for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_companyContact != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.purple),
                      onPressed: _showAddCompanyContactDialog,
                    ),
                  ],
                ),
                const Divider(),
                _buildCapitalRow('Contact Person', _companyContact!.contactPersonName),
                _buildCapitalRow('Mobile', _companyContact!.contactPersonMobile),
                _buildCapitalRow('Email', _companyContact!.contactPersonEmail),
                _buildCapitalRow('How Did Hear', _companyContact!.howDidHear),
                if (_companyContact!.anyOtherMessage != null && _companyContact!.anyOtherMessage!.isNotEmpty)
                  _buildCapitalRow('Message', _companyContact!.anyOtherMessage!),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.contact_phone,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No company contact added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddCompanyContactDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCapitalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 8: REVIEW ====================
  Widget _buildReviewStep() {
    print('🏗️ Building Review Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please review all information before submitting.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Company Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ..._reviewData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_submitMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isSubmitSuccess
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSubmitSuccess
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSubmitSuccess ? Icons.check_circle : Icons.error_outline,
                  color: _isSubmitSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _submitMessage!,
                    style: TextStyle(
                      color: _isSubmitSuccess ? Colors.green : Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _hasAgreedToTerms,
              onChanged: (value) {
                print('🔍 Terms agreement changed: $value');
                setState(() {
                  _hasAgreedToTerms = value ?? false;
                });
              },
              activeColor: Colors.blue,
            ),
            Expanded(
              child: Text(
                'I confirm that all the information provided is accurate and complete.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    print('🏗️ BUILDING CompanyRegistrationScreen - Step: $_currentStep');
    print('🏗️ UserId: "$_userId"');
    print('🏗️ IsSubmitting: $_isSubmitting');
    print('🏗️ ============================================');
    
    if (_userId == null || _userId!.isEmpty) {
      print('⚠️ User not logged in - showing error screen');
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Company Registration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'User not logged in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please login to register a company',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Company Registration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          print('➡️ Step Continue - Current: $_currentStep');
          print('➡️ ============================================');
          if (_currentStep == 7) {
            _submitCompany();
          } else {
            setState(() {
              _currentStep++;
            });
          }
        },
        onStepCancel: () {
          print('⬅️ Step Cancel - Current: $_currentStep');
          print('⬅️ ============================================');
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting ? null : details.onStepCancel,
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 7
                          ? Colors.green
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 7
                                ? 'Submit & Proceed'
                                : 'Save & Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
        steps: _buildSteps(),
      ),
    );
  }
}