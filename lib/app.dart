// import 'package:flutter/material.dart';
// import 'pages/home_feed_page.dart';
// import 'pages/notifications_page.dart';
// import 'pages/dm_page.dart';
// import 'pages/account_page.dart';
// import 'pages/create_post_page.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [
//     HomeFeedPage(),
//     NotificationsPage(),
//     Container(), // Empty container for create button
//     ConversationsListPage(),
//     AccountPage(),
//   ];

//   void _onItemTapped(int index) {
//     if (index == 2) {
//       // Open CreatePostPage as full-screen modal
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true, // Allows full screen expansion
//         backgroundColor: Colors.transparent, // Makes background invisible
//         barrierColor: Colors.black.withOpacity(0.5), // Semi-transparent overlay
//         builder: (context) => Container(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.95,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             child: CreatePostPage(),
//           ),
//         ),
//       );
//     } else {
//       setState(() {
//         _selectedIndex = index;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: Colors.black,
//         bottomNavigationBarTheme: BottomNavigationBarThemeData(
//           backgroundColor: Colors.black,
//           selectedItemColor: Colors.white,
//           unselectedItemColor: Colors.grey,
//         ),
//       ),
//       home: Scaffold(
//         body: _pages[_selectedIndex],
//         bottomNavigationBar: BottomNavigationBar(
//           type: BottomNavigationBarType.fixed,
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.notifications), 
//               label: 'Alerts'),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.add_circle_outline, size: 35), 
//               label: 'Create'),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.message), 
//               label: 'DMs'),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.person), 
//               label: 'Account'),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'pages/home_feed_page.dart';
import 'pages/notifications_page.dart';
import 'pages/dm_page.dart';
import 'pages/account_page.dart';
import 'pages/create_post_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeFeedPage(),
    NotificationsPage(),
    CreatePostPage(), 
    ConversationsListPage(),
    AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 35),
              label: 'Create',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'DMs'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
