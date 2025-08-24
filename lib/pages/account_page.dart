import 'package:flutter/material.dart';
import 'shop_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final List<String> dummyPosts = List.generate(12, (index) => 'https://via.placeholder.com/150');

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
              Text('Settings & Privacy', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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
              Text('Monetization', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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

  Widget _buildPostGrid(List<String> urls) {
    return GridView.builder(
      itemCount: urls.length,
      padding: const EdgeInsets.all(8),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (_, index) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(urls[index]),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Riak', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Header
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
              SizedBox(height: 10),
              Text('Riak Wande', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Text('This is your bio. Add something cool here!', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStat('124', 'Following'),
                  _buildStat('5.3K', 'Followers'),
                  _buildStat('24.1K', 'Likes'),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ), 
                    child: Text('Edit Profile', style: TextStyle(color: Colors.black)),
                  ),
                  // SizedBox(width: 10),
                  // OutlinedButton(
                  //   onPressed: () {},
                  //   style: OutlinedButton.styleFrom(
                  //     side: BorderSide(color: Colors.black),
                  //   ), 
                  //   child: Text('Share Profile', style: TextStyle(color: Colors.black)),
                  // ),
                  SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShopPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ), 
                    child: Text('Shop', style: TextStyle(color: Colors.black)),
                  ),
                  SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SavedPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black),
                    ), 
                    child: Text('Saved', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Posts section with a simple header
          Text('Your Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 10),
          _buildPostGrid(dummyPosts),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Saved Page
class SavedPage extends StatelessWidget {
  final List<String> dummySaved = List.generate(6, (index) => 'https://via.placeholder.com/150/7f7fff');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Contents'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: GridView.builder(
        itemCount: dummySaved.length,
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (_, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(dummySaved[index]),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
}

// Edit Profile Page
class EditProfilePage extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController(text: 'Riak Wande');
  final TextEditingController _bioController = TextEditingController(text: 'This is your bio. Add something cool here!');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () {
              // Save changes logic here
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Change password logic
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}