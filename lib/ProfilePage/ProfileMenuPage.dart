import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/AuthService.dart';
import '../LogInPage/LogIn.dart';
import 'ProfileImageWidget.dart';
import 'SeeMyProfile.dart';
import 'UpdateProfile.dart';
import '../Utils/BaseURL.dart' as BASEURL;
import 'package:http/http.dart' as http;

class ProfileMenuPage extends StatelessWidget {
  final String? userId;
  const ProfileMenuPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ProfileImageWidget(radius: 45)),
          const SizedBox(height: 20),
          if(userId != null)
          profileTile(
            icon: Icons.person,
            title: "My Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeeMyProfile()),
              );
            },
          ),
          if(userId != null)
          profileTile(
            icon: Icons.edit,
            title: "Update Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateProfile()),
              );
            },
          ),
          if(userId != null)
          profileTile(
            icon: Icons.logout,
            title: "Logout",
            color: Colors.orange,
            onTap: () async {
              await AuthService.logout();
              // Pop the profile page and return true to indicate logout
              Navigator.pop(context, true); // ← Return true to signal logout
            },
          ),
          if(userId != null)
          profileTile(
            icon: Icons.delete,
            title: "Delete Account",
            color: Colors.red,
            onTap: () {
              showDeleteDialog(context);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> deleteAccount(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    String? token = prefs.getString("jwt_token");

    var url = Uri.parse("${BASEURL.Urls().baseURL}user/delete/$userId?tryingToDelete=$userId");

    var response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    
    AuthService.getToken();

    if (response.statusCode == 200) {
      print("Account deleted successfully");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body))
        );
      }
      
      await AuthService.logout();
      
      // Pop the profile page and return true to indicate logout
      if (context.mounted) {
        Navigator.pop(context, true); // ← Return true to signal logout
      }
    } else {
      print("Account deletion failed");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deletion failed"))
        );
      }
    }
  }

  static Widget profileTile({
    required IconData icon,
    required String title,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white70,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        onTap: onTap,
      ),
    );
  }

  static void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This action is permanent. Are you sure?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              deleteAccount(context); // Delete account
            },
          ),
        ],
      ),
    );
  }
}