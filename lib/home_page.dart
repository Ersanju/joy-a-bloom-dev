import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joy_a_bloom_dev/pages/authentication/signup_login_page.dart';
import 'package:joy_a_bloom_dev/pages/home/products_by_category_grid_page.dart';
import 'package:joy_a_bloom_dev/pages/home/search_results_page.dart';
import 'package:joy_a_bloom_dev/widgets/product_card.dart';
import 'models/category.dart';
import 'pages/home/delivery_location_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String _locationText = 'Fetching location...';
  String _pinCode = '';
  Map<String, dynamic>? _userData;
  List<String> bannerImages = [];
  bool isLoadingBanners = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _fetchBannerImages();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage =
            (_pageController.page!.round() + 1) % bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupLoginPage(),
                  ),
                );
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
          const SizedBox(height: 10),
          buildCategorySection(),
          buildBannerSlider(),
          SizedBox(height: 10),
          featuredOffersSection(context),
          SizedBox(height: 10),
          newArrivalsSection(),
          SizedBox(height: 10),
          youMayAlsoLikeSection(),
          SizedBox(height: 10),
          appReviewsSection(),
          SizedBox(height: 10),
          brandingSection(),
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
    final nullSnapshot =
        await FirebaseFirestore.instance
            .collection('categories')
            .where('active', isEqualTo: true)
            .where('categoryId', isNull: true)
            .orderBy('priority')
            .get();

    final emptySnapshot =
        await FirebaseFirestore.instance
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
                  buildCategoryItem(context, top),
                  const SizedBox(height: 20),
                  if (bottom != null) buildCategoryItem(context, bottom),
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
            builder:
                (_) => ProductsByCategoryGridPage(
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

  Future<void> _fetchBannerImages() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('banners').get();

      final fetchedImages =
          snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();

      setState(() {
        bannerImages = fetchedImages;
        isLoadingBanners = false;
      });
    } catch (e) {
      debugPrint("Error loading banners: $e");
      setState(() {
        bannerImages = [];
        isLoadingBanners = false;
      });
    }
  }

  Widget buildBannerSlider() {
    if (isLoadingBanners) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (bannerImages.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No banners available")),
      );
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: bannerImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(bannerImages[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget featuredOffersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "🎉 Featured Offers",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 190, // increased to accommodate stacked card layout
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('products')
                    .where('tags', arrayContains: 'featured')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No featured products available.'),
                );
              }

              final products = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                padding: const EdgeInsets.only(left: 16),
                itemBuilder: (context, index) {
                  final product =
                      products[index].data() as Map<String, dynamic>;

                  return ProductCard(productData: product, onTap: () {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget newArrivalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "🆕 New Arrivals",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 190,
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('products')
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No new arrivals found.'));
              }

              final products = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productData =
                      products[index].data() as Map<String, dynamic>;

                  return ProductCard(
                    productData: productData,
                    onTap: () {
                      // Navigate to product details
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget youMayAlsoLikeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "❤️ You May Also Like",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 190,
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('products')
                    .where(
                      'tags',
                      arrayContainsAny: ['recommended', 'trending'],
                    )
                    .limit(10)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No suggestions available.'));
              }

              final products = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productData =
                      products[index].data() as Map<String, dynamic>;

                  return ProductCard(
                    productData: productData,
                    onTap: () {
                      // Navigate to product details
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget appReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "⭐ What Our Customers Say",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('app_reviews')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("No customer reviews yet."),
              );
            }

            final reviews = snapshot.data!.docs;

            return SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final data = reviews[index].data() as Map<String, dynamic>;

                  final userName = data['userName'] ?? 'Anonymous';
                  final city = data['city'] ?? '';
                  final message = data['message'] ?? '';
                  final rating = (data['rating'] ?? 5).toDouble();

                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating stars
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),

                        // Review message
                        Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Spacer(),

                        // User and city
                        Text(
                          "- $userName, $city",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget brandingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🌸 Why Joy-a-Bloom?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          brandingTile(
            "🎁",
            "Curated Gifting",
            "Handpicked items for every celebration.",
          ),
          brandingTile(
            "🚚",
            "On-Time Delivery",
            "Timely, safe delivery you can rely on.",
          ),
          brandingTile(
            "🧁",
            "Premium Quality",
            "Fresh, delicious and beautifully made.",
          ),
          brandingTile("📞", "24x7 Support", "Always here to help, anytime."),
        ],
      ),
    );
  }

  Widget brandingTile(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
