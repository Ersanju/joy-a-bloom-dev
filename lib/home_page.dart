import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joy_a_bloom_dev/pages/home/products_by_category_grid_page.dart';
import 'package:joy_a_bloom_dev/pages/home/search_results_page.dart';
import 'models/category.dart';
import 'pages/home/delivery_location_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _locationText = 'Fetching location...';
  String _pinCode = '';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? buildAppBar() : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryLocationPage(),
                ),
              );

              if (result != null && mounted) {
                setState(() {
                  _pinCode = result['pin'] ?? '';
                  _locationText = result['location'] ?? '';
                });
              }
            },
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.black),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _pinCode,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _userData == null
            ? TextButton(
              onPressed: () {
                // Navigate to login/signup page
              },
              child: const Text(
                "Login / Signup",
                style: TextStyle(color: Colors.black),
              ),
            )
            : Row(
              children: [
                if (_userData!['profileImageUrl'] != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      _userData!['profileImageUrl'],
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _userData!['name'] ?? "User",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
      ],
    );
  }

  Widget buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 5),
          buildSearchBar(context),
          const SizedBox(height: 15),
          buildCategorySection(),
        ],
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Account',
        ),
      ],
    );
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc('ersanjay')
              .get();

      if (userSnapshot.exists) {
        setState(() {
          _userData = userSnapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = 'Location services disabled';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = 'Permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationText = 'Permission permanently denied';
      });
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Convert coordinates to address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _locationText = '${place.locality}, ${place.administrativeArea}';
        _pinCode = '${place.postalCode}';
      });
    } else {
      setState(() {
        _locationText = 'Location not found';
      });
    }
  }

  List<Widget> get _pages => [
    buildHomeContent(),
    Text('data'),
    Text('data'),
    Text('data'),
  ];

  Widget buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: TextField(
        onSubmitted: (query) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultsPage(query: query),
            ),
          );
        },
        decoration: InputDecoration(
          hintText: "Search for cakes, gifts, flowers...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildCategorySection() {
    return FutureBuilder<List<Category>>(
      future: fetchCategoriesFromFirestore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error loading categories');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No categories found');
        }

        final categories = snapshot.data!;
        return buildCategoryList(categories);
      },
    );
  }

  Future<List<Category>> fetchCategoriesFromFirestore() async {
    final nullSnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('active', isEqualTo: true)
        .where('categoryId', isNull: true)
        .orderBy('priority')
        .get();

    final emptySnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('active', isEqualTo: true)
        .where('categoryId', isEqualTo: '')
        .orderBy('priority')
        .get();

    final allDocs = [...nullSnapshot.docs, ...emptySnapshot.docs];
    final seen = <String>{};

    return allDocs.where((doc) => seen.add(doc.id)).map((doc) {
      final data = doc.data();
      return Category(
        id: doc.id,
        name: data['name'],
        categoryId: data['categoryId'],
        imageUrl: data['imageUrl'],
        description: data['description'],
        priority: data['priority'],
        active: data['active'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Widget buildCategoryList(List<Category> categories) {
    final int half = (categories.length / 2).ceil();
    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(half, (index) {
            final top = categories[index];
            final bottom =
                (index + half < categories.length)
                    ? categories[index + half]
                    : null;

            return Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  buildCategoryItem(context,top),
                  const SizedBox(height: 20),
                  if (bottom != null) buildCategoryItem(context,bottom),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget buildCategoryItem(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsByCategoryGridPage(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Hero(
            tag: category.id,
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(category.imageUrl),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }





}
