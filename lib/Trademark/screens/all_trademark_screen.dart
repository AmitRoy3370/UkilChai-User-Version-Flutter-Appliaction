// lib/Trademark/screens/all_trademark_screen.dart

import 'package:flutter/material.dart';
import '../models/trademark_response_dto.dart';
import '../services/trademark_service.dart';
import 'widgets/trademark_card.dart';
import 'trademark_details_screen.dart';

class AllTrademarkScreen extends StatefulWidget {
  const AllTrademarkScreen({super.key});

  @override
  State<AllTrademarkScreen> createState() => _AllTrademarkScreenState();
}

class _AllTrademarkScreenState extends State<AllTrademarkScreen> {
  List<TrademarkResponse> _items = [];
  List<TrademarkResponse> _filtered = [];
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await TrademarkService.findAll();
    if (!mounted) return;

    if (result['status'] == 'success') {
      final list = TrademarkService.parseList(result);
      final approved = list
          .where((c) =>
              c.registrationProcess != null &&
              c.registrationProcess!.status == true)
          .toList();
      setState(() {
        _items = approved;
        _filtered = approved;
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
        return c.trademarkName.toLowerCase().contains(q) ||
            c.userName.toLowerCase().contains(q) ||
            c.trademarkType.toLowerCase().contains(q) ||
            c.classOfGoods.toLowerCase().contains(q);
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
        title: const Text('All Trademark',
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
                hintText: 'Search by name, type, class...',
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
            Icon(Icons.verified_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No approved trademarks yet'
                  : 'No results matching your search',
              style: TextStyle(color: Colors.grey.shade600),
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
          return TrademarkCard(
            trademark: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrademarkDetailsScreen(
                  trademark: item,
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