// lib/vat/screens/all_vat_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/vat_response_model.dart';
import '../service/vat_service.dart';
import 'my_vat_page.dart' show VatCard; // reuse VatCard from my_vat_page

class AllVatPage extends StatefulWidget {
  const AllVatPage({super.key});

  @override
  State<AllVatPage> createState() => _AllVatPageState();
}

class _AllVatPageState extends State<AllVatPage> {
  bool _loading = true;
  String? _error;
  List<VatResponseModel> _vats = [];
  String? _userId;

  // Search
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('_id');

      // Fetch all VATs (backend returns [] or throws if empty)
      final list = await VatService.findAll();

      // Only show VATs that HAVE a registration process AND status == true
      final filtered = list
          .where((v) =>
              v.vatRegistrationProcessResponseDTO != null &&
              v.vatRegistrationProcessResponseDTO!.status == true)
          .toList();

      if (!mounted) return;
      setState(() {
        _vats = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('No such vat') ||
          msg.contains('NoSuchElementException')) {
        setState(() {
          _vats = [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = msg.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<VatResponseModel> get _visibleVats {
    if (_query.trim().isEmpty) return _vats;
    final q = _query.trim().toLowerCase();
    return _vats.where((v) {
      return v.buisnessName.toLowerCase().contains(q) ||
          v.tinNo.toLowerCase().contains(q) ||
          v.tradeLicenseNo.toLowerCase().contains(q) ||
          v.userName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'All VAT',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                icon: Icon(Icons.search,
                    color: Colors.grey.shade500, size: 20),
                hintText: 'Search by name, TIN, or license no.',
                hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                border: InputBorder.none,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  )
                : _error != null
                    ? _buildError()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final list = _visibleVats;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'No matching VAT found'
                  : 'No VAT available',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => VatCard(
          vat: list[i],
          currentUserId: _userId,
          onChanged: _load,
        ),
      ),
    );
  }
}