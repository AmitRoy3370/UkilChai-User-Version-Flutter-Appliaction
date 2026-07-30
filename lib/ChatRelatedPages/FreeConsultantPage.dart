import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import './CenterAdminChatListScreen.dart';

class FreeConsultantPage extends StatefulWidget {
  final String? currentUserId, currentUserName;
  const FreeConsultantPage({super.key, required this.currentUserId, required this.currentUserName});

  @override
  State<FreeConsultantPage> createState() => _FreeConsultantPageState();
}

class _FreeConsultantPageState extends State<FreeConsultantPage> {
  // লিংক ওপেন করার ফাংশন
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      final Uri emailUri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _goToChat() {
    if (widget.currentUserId != null && widget.currentUserName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CenterAdminChatListScreen(
            currentUserId: widget.currentUserId!,
            currentUserName: widget.currentUserName!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== হেডার সেকশন - গ্রিন কালার =====
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // ===== কন্ট্যাক্ট সেকশন =====
              _buildContactSection(),
              
              const SizedBox(height: 24),
              
              // ===== হেল্প সেকশন =====
              _buildHelpSection(),
              
              const SizedBox(height: 24),
              
              // ===== চ্যাট বাটন =====
              //_buildChatButton(),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===== হেডার - গ্রিন কালার =====
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00695C),  // Dark Green
            Color(0xFF00897B),  // Medium Green
            Color(0xFF26A69A),  // Light Green
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // টেক্সট অংশ
          const Text(
            'Talk to Our Customer Care Team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Get free legal advice and guidance on\nyour legal concerns. We are here to help!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          
          // Available Time - ব্যাজ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Available Time',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '10:00 AM - 10:00 PM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '(Everyday)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== কন্ট্যাক্ট সেকশন =====
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
          ),
          
          // ফোন
          _buildContactCard(
            icon: Icons.phone,
            iconColor: Colors.green,
            title: 'Phone Number',
            subtitle: '+880 1815 696208',
            action: 'Call Now',
            bgColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFFA5D6A7),
            onTap: () => _makePhoneCall('+8801815696208'),
          ),
          
          // হোয়াটসঅ্যাপ
          _buildContactCard(
            icon: Icons.chat,
            iconColor: Colors.green,
            title: 'WhatsApp',
            subtitle: 'Chat with us on WhatsApp',
            action: 'Chat Now',
            bgColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFFA5D6A7),
            onTap: () => _launchURL('https://wa.me/8801815696208'),
          ),
          
          // ফেসবুক
          _buildContactCard(
            icon: Icons.facebook,
            iconColor: const Color(0xFF1565C0),
            title: 'Facebook Page',
            subtitle: 'm.me/ukil.com.bd',
            action: 'Message',
            bgColor: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFF90CAF9),
            onTap: () => _launchURL('https://www.facebook.com/share/1LakTv4oRP/'),
          ),
          
          // লিংকডইন
          _buildContactCard(
            icon: Icons.work,
            iconColor: const Color(0xFF1565C0),
            title: 'LinkedIn',
            subtitle: 'linkedin.com/company/ukil',
            action: 'Follow',
            bgColor: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFF90CAF9),
            onTap: () => _launchURL('https://www.linkedin.com/company/%E0%A6%89%E0%A6%95%E0%A6%BF%E0%A6%B2-ukil/'),
          ),
          
          // ইমেইল
          _buildContactCard(
            icon: Icons.email,
            iconColor: const Color(0xFFE65100),
            title: 'Email Us',
            subtitle: 'support@ukil.com.bd',
            action: 'Send Email',
            bgColor: const Color(0xFFFFF3E0),
            borderColor: const Color(0xFFFFCC80),
            onTap: () => _sendEmail('support@ukil.com.bd'),
          ),
          
          // লাইভ চ্যাট
          _buildContactCard(
            icon: Icons.live_help,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Live Chat',
            subtitle: 'Chat instantly with our team',
            action: 'Start Chat',
            bgColor: const Color(0xFFF3E5F5),
            borderColor: const Color(0xFFCE93D8),
            onTap: _goToChat,
          ),
        ],
      ),
    );
  }

  // ===== কন্ট্যাক্ট কার্ড =====
  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String action,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ===== হেল্প সেকশন =====
  Widget _buildHelpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'What can we help with?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHelpItem('General legal information and guidance'),
                _buildDivider(),
                _buildHelpItem('Questions about legal rights and procedures'),
                _buildDivider(),
                _buildHelpItem('Help with documents and legal processes'),
                _buildDivider(),
                _buildHelpItem('Guide you to the right advocate if needed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== হেল্প আইটেম =====
  Widget _buildHelpItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF00695C),
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ডিভাইডার =====
  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      color: Colors.grey.shade200,
      thickness: 0.5,
    );
  }

  // ===== চ্যাট বাটন =====
  Widget _buildChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _goToChat,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00695C),
                Color(0xFF00897B),
                Color(0xFF26A69A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00695C).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Start Chat with Advocate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}