import 'dart:convert';

import 'package:advocatechai/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechai/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechai/ProfilePage/ProfileAvatar.dart';
import 'package:advocatechai/ProfilePage/ProfileImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ChatRelatedPages/AllUserChatListScreen.dart';
import 'HomePage.dart';
import 'LogInPage/LogIn.dart';
import 'PostRelatedPages/post_feed_page_home_page.dart';
import 'ProfilePage/ProfileMenuPage.dart';
import 'Utils/BaseURL.dart' as BASE_URL;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'উকিল',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'উকিল চাই'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int index = 0;

Future<String?> getMyId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? myId = prefs.getString('userId');
  return myId;
}

Future<String?> getMyName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? myId = prefs.getString('userId');
  String? token = prefs.getString('jwt_token');

  final response = await http.get(
    Uri.parse("${BASE_URL.Urls().baseURL}user/$myId"),
    headers: {
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['name'];
  } else {
    return "";
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> bottomPages = [];
  bool isLoading = true;

  String? myId, myName;

  @override
  void initState() {
    super.initState();

    loadAllUser();
  }

  Future<void> loadAllUser() async {
    myId = await getMyId();
    myName = await getMyName();

    bottomPages = [
      Homepage(),
      PostFeedPage(),
      AdvocateFilterPage(),
      AllUserChatListScreen(currentUserId: myId, currentUserName: myName),
      LogIn(),
    ];

    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,

      appBar: AppBar(
        title: Text("উকিল"),
        centerTitle: true,
        backgroundColor: Colors.green,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileMenuPage()),
                );
              },
              child: ProfileImageWidget(),
            ),
          ),
        ],
      ),
      body: index == 3
          ? AllUserChatListScreen(currentUserId: myId, currentUserName: myName)
          : bottomPages[index],

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: "Articles",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Advocate",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: "LogIn",
            backgroundColor: Colors.black,
          ),
        ],
        currentIndex: index,
        onTap: (value) {
          setState(() async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "clicked Index: $value and previous index : $index",
                ),
                duration: Duration(seconds: 2),
              ),
            );

            setState(() {
              index = value;
            });

            myId = await getMyId();
            myName = await getMyName();
          });
        },
      ),
    );
  }
}
