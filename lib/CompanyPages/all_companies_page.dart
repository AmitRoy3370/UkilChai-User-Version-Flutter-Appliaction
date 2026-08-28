// lib/CompanyPages/all_companies_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../CompanyPages/company_service.dart';
import '../CompanyPages/company_response.dart';
import '../CompanyPages/company_details_page.dart';
import '../Auth/AuthService.dart';

class AllCompaniesPage extends StatefulWidget {
  const AllCompaniesPage({Key? key}) : super(key: key);

  @override
  State<AllCompaniesPage> createState() => _AllCompaniesPageState();
}

class _AllCompaniesPageState extends State<AllCompaniesPage> {
  final CompanyService _companyService = CompanyService();
  List<CompanyResponse> _allCompanies = [];
  List<CompanyResponse> _filteredCompanies = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  
  // Filter states
  String? _selectedType;
  String? _selectedCategory;
  String? _selectedNatureOfBusiness;
  
  // Filter options
  final List<String> _types = [];
  final List<String> _categories = [];
  final List<String> _natureOfBusiness = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please login to view companies');
      }

      final companies = await _companyService.getAllCompanies();
      
      // Extract unique filter options
      _types.clear();
      _categories.clear();
      _natureOfBusiness.clear();
      
      for (var company in companies) {
        if (company.type != null && company.type!.isNotEmpty && !_types.contains(company.type)) {
          _types.add(company.type!);
        }
        if (company.category != null && company.category!.isNotEmpty && !_categories.contains(company.category)) {
          _categories.add(company.category!);
        }
        if (company.natureOfBusiness != null && company.natureOfBusiness!.isNotEmpty && !_natureOfBusiness.contains(company.natureOfBusiness)) {
          _natureOfBusiness.add(company.natureOfBusiness!);
        }
      }

      setState(() {
        _allCompanies = companies;
        _filteredCompanies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCompanies = _allCompanies.where((company) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = company.companyName.toLowerCase().contains(query) ||
              (company.type?.toLowerCase().contains(query) ?? false) ||
              (company.category?.toLowerCase().contains(query) ?? false) ||
              (company.natureOfBusiness?.toLowerCase().contains(query) ?? false);
          if (!matchesSearch) return false;
        }
        
        // Type filter
        if (_selectedType != null && _selectedType!.isNotEmpty) {
          if (company.type != _selectedType) return false;
        }
        
        // Category filter
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          if (company.category != _selectedCategory) return false;
        }
        
        // Nature of Business filter
        if (_selectedNatureOfBusiness != null && _selectedNatureOfBusiness!.isNotEmpty) {
          if (company.natureOfBusiness != _selectedNatureOfBusiness) return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCategory = null;
      _selectedNatureOfBusiness = null;
      _filteredCompanies = _allCompanies;
    });
  }

  void _navigateToCompanyDetail(String companyId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return CompanyDetailsPage(companyId: companyId);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final crossAxisCount = isDesktop ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Companies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Search Bar
                    _buildSearchBar(),
                    
                    // Filter Chips
                    if (_types.isNotEmpty || _categories.isNotEmpty || _natureOfBusiness.isNotEmpty)
                      _buildFilterChips(),
                    
                    // Results Count
                    _buildResultsCount(),
                    
                    // Companies Grid
                    Expanded(
                      child: _filteredCompanies.isEmpty
                          ? _buildEmptyWidget()
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _filteredCompanies.length,
                              itemBuilder: (context, index) {
                                final company = _filteredCompanies[index];
                                return _buildCompanyCard(company);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCompanies,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedType != null || _selectedCategory != null || _selectedNatureOfBusiness != null
                ? 'No companies match your filters'
                : 'No companies found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedType != null || _selectedCategory != null || _selectedNatureOfBusiness != null)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search companies...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Type Filter
          if (_types.isNotEmpty)
            _buildFilterChip(
              label: 'Type',
              options: _types,
              selectedValue: _selectedType,
              onSelected: (value) {
                setState(() {
                  _selectedType = value;
                  _applyFilters();
                });
              },
            ),
          
          const SizedBox(width: 8),
          
          // Category Filter
          if (_categories.isNotEmpty)
            _buildFilterChip(
              label: 'Category',
              options: _categories,
              selectedValue: _selectedCategory,
              onSelected: (value) {
                setState(() {
                  _selectedCategory = value;
                  _applyFilters();
                });
              },
            ),
          
          const SizedBox(width: 8),
          
          // Nature of Business Filter
          if (_natureOfBusiness.isNotEmpty)
            _buildFilterChip(
              label: 'Nature',
              options: _natureOfBusiness,
              selectedValue: _selectedNatureOfBusiness,
              onSelected: (value) {
                setState(() {
                  _selectedNatureOfBusiness = value;
                  _applyFilters();
                });
              },
            ),
          
          // Clear All button
          if (_selectedType != null || _selectedCategory != null || _selectedNatureOfBusiness != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ActionChip(
                label: const Text('Clear All'),
                onPressed: _clearFilters,
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onSelected,
  }) {
    return FilterChip(
      label: Text(
        selectedValue ?? label,
        style: TextStyle(
          fontWeight: selectedValue != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selectedValue != null,
      onSelected: (selected) {
        if (selected) {
          // Show dropdown or selection dialog
          _showFilterOptionsDialog(label, options, selectedValue, onSelected);
        } else {
          onSelected(null);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _showFilterOptionsDialog(
    String label,
    List<String> options,
    String? currentValue,
    Function(String?) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select $label',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ...options.map((option) => ListTile(
              title: Text(option),
              trailing: currentValue == option
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelected(option);
              },
            )),
            const Divider(),
            ListTile(
              title: const Text('Clear Filter'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onSelected(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredCompanies.length} company${_filteredCompanies.length != 1 ? 'ies' : ''} found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (_filteredCompanies.length != _allCompanies.length)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Show All'),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(CompanyResponse company) {
    return GestureDetector(
      onTap: () => _navigateToCompanyDetail(company.id!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo/Icon Section
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.business,
                    color: Colors.blue.shade700,
                    size: 30,
                  ),
                ),
              ),
            ),
            
            // Company Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.companyName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company.type ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (company.category != null && company.category!.isNotEmpty)
                          _buildSmallTag(company.category!),
                        if (company.directorsName != null && company.directorsName!.isNotEmpty)
                          _buildSmallTag('${company.directorsName!.length} Directors'),
                        if (company.shareHoldersName != null && company.shareHoldersName!.isNotEmpty)
                          _buildSmallTag('${company.shareHoldersName!.length} Shareholders'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}