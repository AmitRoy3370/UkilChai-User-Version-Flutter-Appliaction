import 'package:flutter/material.dart';
import 'selection_page.dart'; // একই ফোল্ডারে থাকা SelectionPage ইমপোর্ট করা হলো

class CorporateBanner extends StatelessWidget {
  const CorporateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // কার্ডের ডিজাইন ও শ্যাডো
      decoration: BoxDecoration(
        color: const Color(0xFF0B5D36), // ছবির মত ডার্ক গ্রিন কালার
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ১. বাম দিকের টেক্সট এবং বাটন অংশ
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Ukil Corporate",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "All Corporate & Business\nLegal Services",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Explore বাটন
                ElevatedButton(
                  onPressed: () {
                    // এখানে ক্লিক করলে SelectionPage এ নিয়ে যাবে
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectionPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B5D36),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Explore",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // ২. ডান দিকের বিল্ডিং আইকন (ইলাস্ট্রেশন)
          Positioned(
            right: 20,
            bottom: 0, 
            top: 20,
            child: Opacity(
              opacity: 0.9,
              child: Icon(
                Icons.apartment, // বিল্ডিং এর আইকন
                size: 100,
                color: Colors.white.withOpacity(0.3), 
              ),
            ),
          ),

          // ৩. ডান দিকের উপরের এরো (Arrow) বাটন
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}