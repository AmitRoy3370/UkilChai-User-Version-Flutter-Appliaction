// lib/Tin/screens/all_tin_screen.dart

import 'package:flutter/material.dart';
import '../models/tin_response_dto.dart';
import '../services/tin_service.dart';
import 'widgets/tin_card.dart';
import 'tin_details_screen.dart';

class AllTinScreen extends StatefulWidget {
  const AllTinScreen({super.key});

  @override
  State<AllTinScreen> createState() => _AllTinScreenState();
}

class _AllTinScreenState extends State<AllTinScreen> {
  List<TinResponseDTO> _items = [];
  List<TinResponseDTO> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ Approved = registration process is NOT null
  bool _isApproved(TinResponseDTO tin) {
    return tin.registrationProcess != null;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await TinService.findAll();
    if (!mounted) return;

    if (result['status'] == 'success') {
      // ✅ All TIN page এ শুধু approved গুলো দেখাব
      final all = TinService.parseList(result);
      final approvedOnly = all.where(_isApproved).toList();

      print('📊 All TIN: Total=${all.length}, Approved=${approvedOnly.length}');

      setState(() {
        _items = approvedOnly;
        _filtered = approvedOnly;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? 'Failed to load';
      });
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _items);
      return;
    }
    setState(() {
      _filtered = _items.where((c) {
        return c.fullName.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.fatherName.toLowerCase().contains(q) ||
            c.userName.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('All TIN',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, father...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchController.text.isEmpty
                    ? 'No approved TIN registrations yet'
                    : 'No results matching your search',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = _filtered[i];
          return TinCard(
            tin: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TinDetailsScreen(
                  tin: item,
                  isOwner: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}