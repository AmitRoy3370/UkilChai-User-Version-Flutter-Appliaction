import 'package:flutter/material.dart';
import '../ChatRelatedPages/admin_chat_screen_page.dart'; // Make sure this path is correct for your project

// ==================== DATA ====================
const List<String> _bangladeshDistricts = [
  "Barguna", "Barisal", "Bhola", "Jhalokati", "Patuakhali", "Pirojpur",
  "Bandarban", "Brahmanbaria", "Chandpur", "Chittagong", "Comilla", "Cox's Bazar", "Feni", "Khagrachhari", "Lakshmipur", "Noakhali", "Rangamati",
  "Dhaka", "Faridpur", "Gazipur", "Gopalganj", "Kishoreganj", "Madaripur", "Manikganj", "Munshiganj", "Narayanganj", "Narsingdi", "Rajbari", "Shariatpur", "Tangail",
  "Bagerhat", "Chuadanga", "Jessore", "Jhenaidah", "Khulna", "Kushtia", "Magura", "Meherpur", "Narail", "Satkhira",
  "Jamalpur", "Mymensingh", "Netrokona", "Sherpur",
  "Bogra", "Joypurhat", "Naogaon", "Natore", "Chapai Nawabganj", "Pabna", "Rajshahi", "Sirajganj",
  "Dinajpur", "Gaibandha", "Kurigram", "Lalmonirhat", "Nilphamari", "Panchagarh", "Rangpur", "Thakurgaon",
  "Habiganj", "Moulvibazar", "Sunamganj", "Sylhet",
];

// ==================== PAGE ====================

class DistrictSelectionPage extends StatefulWidget {
  final String? preSelectedDistrict, currentUserId, currentUserName;

  const DistrictSelectionPage({
    Key? key, 
    this.preSelectedDistrict, 
    this.currentUserId, 
    this.currentUserName
  }) : super(key: key);

  @override
  _DistrictSelectionPageState createState() => _DistrictSelectionPageState();
}

class _DistrictSelectionPageState extends State<DistrictSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredDistricts = [];
  String _selectedDistrict = "";

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.preSelectedDistrict ?? "";
    _filteredDistricts = _bangladeshDistricts;
    _searchController.addListener(_filterDistricts);
  }

  void _filterDistricts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDistricts = _bangladeshDistricts.where((district) {
        return district.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectDistrict(String district) {
    setState(() {
      _selectedDistrict = district;
    });
  }

  void _confirmSelection() {
    if (_selectedDistrict.isNotEmpty) {
      // 🛠️ FIX: Changed ':-' to ':' for named parameters
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminChatScreenPage(
            currentUserId: widget.currentUserId!,
            currentUserName: widget.currentUserName!,
            district: _selectedDistrict, // ✅ Corrected syntax
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a district first."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select District"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_selectedDistrict.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  "✓ $_selectedDistrict",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search district...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // --- List of Districts ---
          Expanded(
            child: _filteredDistricts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          "No districts found",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDistricts.length,
                    itemBuilder: (context, index) {
                      final district = _filteredDistricts[index];
                      final isSelected = district == _selectedDistrict;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.green : Colors.grey[200],
                          child: Icon(
                            isSelected ? Icons.check : Icons.location_on,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          district,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.green : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () => _selectDistrict(district),
                      );
                    },
                  ),
          ),

          // --- Confirm Button ---
          if (_selectedDistrict.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Confirm Selection",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}