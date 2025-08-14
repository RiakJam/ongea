import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ads Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ShopPage(),
    );
  }
}

class ShopPage extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final List<String> userAds = [
    'https://images.unsplash.com/photo-1611162616475-46b635cb6868?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
    'https://images.unsplash.com/photo-1579389083078-4e7018379f7e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
    'https://images.unsplash.com/photo-1611162616305-c69b3fa7fbe0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
    'https://images.unsplash.com/photo-1574717024453-3545edf62f6b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
    'https://images.unsplash.com/photo-1551818255-e6e10975bc17?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1132&q=80',
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
  ];

  final List<Map<String, dynamic>> userPosts = [
    {
      'id': '1',
      'image': 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1172&q=80',
      'caption': 'Check out our new collection!',
      'date': '2 days ago',
    },
    {
      'id': '2',
      'image': 'https://images.unsplash.com/photo-1467232004584-a241de8bcf5d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1169&q=80',
      'caption': 'Summer sale starts tomorrow!',
      'date': '1 week ago',
    },
    {
      'id': '3',
      'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      'caption': 'Behind the scenes at our factory',
      'date': '3 weeks ago',
    },
  ];

  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Ads Manager', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Run Ads', 0),
                _buildTabButton('Ads', 1),
                _buildTabButton('Analytics', 2),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildRunAdsTab(),
                _buildAdsGrid(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _currentIndex == index ? Colors.black : Colors.white,
        foregroundColor: _currentIndex == index ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildRunAdsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Ad Campaign',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 20),
          _buildAdOption(
            'Boost Post',
            'Reach more people with your content',
            Icons.trending_up,
            onTap: () => _showBoostPostDialog(),
          ),
          _buildAdOption(
            'Promote Product',
            'Highlight your products to potential customers',
            Icons.shopping_bag,
            onTap: () => _showPromoteProductDialog(),
          ),
          _buildAdOption(
            'Website Traffic',
            'Drive visitors to your website',
            Icons.link,
            onTap: () => _showWebsiteTrafficDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: userAds.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showAdDetails(userAds[index]),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(userAds[index]),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _editAd(userAds[index]),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ad Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 20),
          _buildMetricCard('Impressions', '24,567', Icons.remove_red_eye),
          _buildMetricCard('Clicks', '1,234', Icons.touch_app),
          _buildMetricCard('Engagement', '8.5%', Icons.thumb_up),
          _buildMetricCard('Spend', '\$245.50', Icons.attach_money),
          SizedBox(height: 20),
          Text(
            'Recent Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 10),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Performance Chart',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdOption(String title, String description, IconData icon, {VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: TextStyle(color: Colors.white)),
        trailing: Icon(Icons.chevron_right, color: Colors.white),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickMedia(bool isImage) async {
    final picker = ImagePicker();
    final pickedFile = await (isImage 
        ? picker.pickImage(source: ImageSource.gallery)
        : picker.pickVideo(source: ImageSource.gallery));
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void _showBoostPostDialog() {
    Map<String, bool> selectedPosts = {};
    for (var post in userPosts) {
      selectedPosts[post['id']] = false;
    }
    
    int selectedDays = 1;
    double estimatedPrice = 5.0;
    int estimatedReach = 1000;
    
    final Map<int, Map<String, dynamic>> pricing = {
      1: {'price': 5.0, 'reach': 1000},
      3: {'price': 12.0, 'reach': 3500},
      7: {'price': 25.0, 'reach': 8000},
      14: {'price': 45.0, 'reach': 18000},
      30: {'price': 90.0, 'reach': 40000},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Boost Post',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: Colors.black),
                SizedBox(height: 16),
                Text('Select posts to boost:', style: TextStyle(fontSize: 16, color: Colors.black)),
                SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: userPosts.map((post) => CheckboxListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(post['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(post['caption'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black)),
                          Text(post['date'], style: TextStyle(color: Colors.black, fontSize: 12)),
                        ],
                      ),
                      value: selectedPosts[post['id']],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedPosts[post['id']] = value!;
                          estimatedPrice = pricing[selectedDays]!['price'] * selectedPosts.values.where((v) => v).length;
                          estimatedReach = pricing[selectedDays]!['reach'] * selectedPosts.values.where((v) => v).length;
                        });
                      },
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    )).toList(),
                  ),
                ),
                SizedBox(height: 16),
                Text('Duration:', style: TextStyle(fontSize: 16, color: Colors.black)),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedDays,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.black),
                    items: [1, 3, 7, 14, 30].map((days) {
                      return DropdownMenuItem<int>(
                        value: days,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('$days day${days > 1 ? 's' : ''}', style: TextStyle(color: Colors.black)),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDays = value!;
                        estimatedPrice = pricing[selectedDays]!['price'] * selectedPosts.values.where((v) => v).length;
                        estimatedReach = pricing[selectedDays]!['reach'] * selectedPosts.values.where((v) => v).length;
                      });
                    },
                  ),
                ),
                SizedBox(height: 24), // Increased spacing here
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Reach:', style: TextStyle(fontSize: 16, color: Colors.black)),
                    Text('$estimatedReach people', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Price:', style: TextStyle(fontSize: 16, color: Colors.black)),
                    Text('\$${estimatedPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: selectedPosts.values.every((element) => !element) ? null : () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Posts boosted for $selectedDays days for \$${estimatedPrice.toStringAsFixed(2)}!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text('Boost Post'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPromoteProductDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    bool isImageSelected = true;
    List<File> selectedMedia = [];
    int selectedDays = 1;
    double estimatedPrice = 10.0;
    int estimatedReach = 2000;
    
    final Map<int, Map<String, dynamic>> pricing = {
      1: {'price': 10.0, 'reach': 2000},
      3: {'price': 25.0, 'reach': 7000},
      7: {'price': 50.0, 'reach': 16000},
      14: {'price': 90.0, 'reach': 36000},
      30: {'price': 180.0, 'reach': 80000},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.9,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Promote Product',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black),
                  SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Product Title',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 16),
                  Text('Media Type:', style: TextStyle(fontSize: 16, color: Colors.black)),
                  Row(
                    children: [
                      Checkbox(
                        value: isImageSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isImageSelected = value!;
                            selectedMedia = [];
                          });
                        },
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                      ),
                      Text('Image', style: TextStyle(color: Colors.black)),
                      SizedBox(width: 20),
                      Checkbox(
                        value: !isImageSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isImageSelected = !value!;
                            selectedMedia = [];
                          });
                        },
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                      ),
                      Text('Video', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final media = await _pickMedia(isImageSelected);
                      if (media != null) {
                        setState(() {
                          selectedMedia.add(media);
                          estimatedPrice = pricing[selectedDays]!['price'] * selectedMedia.length;
                          estimatedReach = pricing[selectedDays]!['reach'] * selectedMedia.length;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text('Add ${isImageSelected ? 'Image' : 'Video'}'),
                  ),
                  if (selectedMedia.isNotEmpty) SizedBox(height: 10),
                  if (selectedMedia.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedMedia.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: isImageSelected
                                ? Image.file(selectedMedia[index], height: 150, width: 150, fit: BoxFit.cover)
                                : Container(
                                    width: 150,
                                    color: Colors.black,
                                    child: Center(
                                      child: Icon(Icons.play_arrow, size: 50, color: Colors.white),
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Product Description',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Text('Duration:', style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedDays,
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.black),
                      items: [1, 3, 7, 14, 30].map((days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('$days day${days > 1 ? 's' : ''}', style: TextStyle(color: Colors.black)),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDays = value!;
                          estimatedPrice = pricing[selectedDays]!['price'] * selectedMedia.length;
                          estimatedReach = pricing[selectedDays]!['reach'] * selectedMedia.length;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 24), // Increased spacing here
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Reach:', style: TextStyle(fontSize: 16, color: Colors.black)),
                      Text('$estimatedReach people', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Price:', style: TextStyle(fontSize: 16, color: Colors.black)),
                      Text('\$${estimatedPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: titleController.text.isEmpty || selectedMedia.isEmpty ? null : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${titleController.text}" promoted for $selectedDays days for \$${estimatedPrice.toStringAsFixed(2)}!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text('Promote Product'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWebsiteTrafficDialog() {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    int selectedDays = 1;
    double estimatedPrice = 8.0;
    int estimatedReach = 1500;
    
    final Map<int, Map<String, dynamic>> pricing = {
      1: {'price': 8.0, 'reach': 1500},
      3: {'price': 20.0, 'reach': 5000},
      7: {'price': 40.0, 'reach': 12000},
      14: {'price': 75.0, 'reach': 30000},
      30: {'price': 150.0, 'reach': 70000},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.9,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Drive Website Traffic',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black),
                  SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Website Title',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'Website URL',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      hintText: 'https://example.com',
                    ),
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(height: 16),
                  Text('Landing Page Preview:', style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 10),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: urlController.text.isEmpty
                        ? Center(child: Text('Enter URL to see preview', style: TextStyle(color: Colors.black)))
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.public, size: 40, color: Colors.black),
                                SizedBox(height: 8),
                                Text(
                                  titleController.text.isEmpty ? 'Website Preview' : titleController.text,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  urlController.text.isEmpty ? 'example.com' : urlController.text.replaceAll(RegExp(r'^https?://'), ''),
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: 16),
                  Text('Duration:', style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedDays,
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.black),
                      items: [1, 3, 7, 14, 30].map((days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('$days day${days > 1 ? 's' : ''}', style: TextStyle(color: Colors.black)),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDays = value!;
                          estimatedPrice = pricing[selectedDays]!['price'];
                          estimatedReach = pricing[selectedDays]!['reach'];
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 24), // Increased spacing here
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Reach:', style: TextStyle(fontSize: 16, color: Colors.black)),
                      Text('$estimatedReach visitors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Price:', style: TextStyle(fontSize: 16, color: Colors.black)),
                      Text('\$${estimatedPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: urlController.text.isEmpty ? null : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Traffic campaign for "${titleController.text}" created for $selectedDays days for \$${estimatedPrice.toStringAsFixed(2)}!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text('Create Campaign'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdDetails(String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ad Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: Colors.black),
            SizedBox(height: 16),
            Expanded(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Impressions:', style: TextStyle(color: Colors.black)),
                    Text('1,234', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Clicks:', style: TextStyle(color: Colors.black)),
                    Text('56', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CTR:', style: TextStyle(color: Colors.black)),
                    Text('4.5%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _editAd(String imageUrl) {
    final TextEditingController textController = TextEditingController(text: 'Promotional content');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Ad',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: Colors.black),
            SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Ad Text',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              style: TextStyle(color: Colors.black),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ad updated successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
