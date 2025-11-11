import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'users_post.dart';
import 'edit_page.dart';
import 'shop_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool loadingUser = true;
  bool _isMounted = false;

  int postCount = 0;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserData();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!_isMounted) return;

    if (mounted) {
      setState(() => loadingUser = true);
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => loadingUser = false);
      }
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() => userData = doc.data());
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }

    if (mounted) {
      setState(() => loadingUser = false);
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Settings & Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Divider(),
              ListTile(
                leading: Icon(Icons.lock, color: Colors.black),
                title: Text('Privacy Settings', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.monetization_on, color: Colors.black),
                title: Text('Monetization & Payments', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _showMonetization();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.black),
                title: Text('Log Out', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonetization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Monetization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Divider(),
              ListTile(
                leading: Icon(Icons.attach_money, color: Colors.black),
                title: Text('Earnings Dashboard', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.black),
                title: Text('Payment Methods', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.analytics, color: Colors.black),
                title: Text('Content Performance', style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutlinedButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.black)),
      child: Text(text, style: TextStyle(color: Colors.black)),
    );
  }

  Widget _buildStat(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (userData != null ? (userData!['fullName'] ?? userData!['username']) : 'Riak')?.toString() ?? 'Riak';
    final bio = (userData != null ? (userData!['bio'] ?? '') : '')?.toString() ?? '';
    final username = (userData != null ? (userData!['username'] ?? '') : '')?.toString() ?? '';
    final avatarUrl = (userData != null ? (userData!['avatarUrl'] ?? '') : '')?.toString() ?? '';

    final followingCount = userData?['followingCount']?.toString() ?? '0';
    final followersCount = userData?['followersCount']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.settings, color: Colors.black), onPressed: _openSettings),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Column(
                children: [
                  ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (c, e, s) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: 36, color: Colors.grey[600]),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 36, color: Colors.grey[600]),
                          ),
                  ),

                  const SizedBox(height: 10),
                  Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('@$username', style: TextStyle(color: Colors.grey[700])),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(bio, textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat(followingCount, 'Following'),
                      _buildStat(followersCount, 'Followers'),
                      _buildStat(postCount.toString(), 'Posts'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildOutlinedButton('Edit Profile', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage()));
                      }),
                      _buildOutlinedButton('Shop', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage()));
                      }),
                      _buildOutlinedButton('Saved', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SavedPage()));
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Your Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 10),
              UsersPost(onPostCountChanged: (count) {
                setState(() => postCount = count);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
