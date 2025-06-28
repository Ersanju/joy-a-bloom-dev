import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joy_a_bloom_dev/pages/account_page/account_page.dart';
import 'package:joy_a_bloom_dev/pages/authentication/signup_login_page.dart';
import 'package:joy_a_bloom_dev/pages/category/category_page.dart';
import 'package:joy_a_bloom_dev/pages/home/products_by_category_grid_page.dart';
import 'package:joy_a_bloom_dev/pages/home/search_results_page.dart';
import 'package:joy_a_bloom_dev/pages/product_detail_page.dart';
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
  bool isHomeLoading = true;
  List<Category> categories = [];
  List<String> bannerImages = [];
  List<Map<String, dynamic>> featuredProducts = [];
  List<Map<String, dynamic>> newArrivals = [];
  List<Map<String, dynamic>> youMayAlsoLikeProducts = [];
  List<Map<String, dynamic>> appReviews = [];
  String _locationText = 'Fetching location...';
  String _pinCode = '';
  Map<String, dynamic>? _userData;

  bool isLoadingBanners = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAllHomeData();
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
    if (isHomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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

  Future<void> _loadAllHomeData() async {
    try {
      setState(() => isHomeLoading = true);

      // 1. Categories (null and empty categoryId)
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

      categories =
          allDocs.where((doc) => seen.add(doc.id)).map((doc) {
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

      // 2. Other Firestore collections
      final bannerFuture =
          FirebaseFirestore.instance
              .collection('banners')
              .where('active', isEqualTo: true)
              .get();

      final featuredFuture =
          FirebaseFirestore.instance
              .collection('products')
              .where('tags', arrayContains: 'featured')
              .get();

      final newArrivalsFuture =
          FirebaseFirestore.instance
              .collection('products')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

      final youMayAlsoLikeFuture =
          FirebaseFirestore.instance
              .collection('products')
              .where('tags', arrayContainsAny: ['recommended', 'trending'])
              .limit(10)
              .get();

      final appReviewsFuture =
          FirebaseFirestore.instance
              .collection('app_reviews')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

      // 3. Run all futures in parallel
      final results = await Future.wait([
        bannerFuture,
        featuredFuture,
        newArrivalsFuture,
        youMayAlsoLikeFuture,
        appReviewsFuture,
      ]);

      final bannerSnapshot = results[0] as QuerySnapshot;
      final featuredSnapshot = results[1] as QuerySnapshot;
      final newArrivalsSnapshot = results[2] as QuerySnapshot;
      final youMayAlsoLikeSnapshot = results[3] as QuerySnapshot;
      final appReviewsSnapshot = results[4] as QuerySnapshot;

      // 4. Update state with all fetched data
      setState(() {
        bannerImages =
            bannerSnapshot.docs
                .map((doc) => doc['imageUrl'] as String)
                .toList();

        featuredProducts =
            featuredSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

        newArrivals =
            newArrivalsSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

        youMayAlsoLikeProducts =
            youMayAlsoLikeSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

        appReviews =
            appReviewsSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

        isHomeLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading homepage data: $e");
      setState(() => isHomeLoading = false); // fallback: show partial UI
    }
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
    CategoryPage(),
    Text('data'),
    AccountPage(),
  ];

  Widget buildSearchBar(BuildContext context) {
    final List<String> hints = [
      "Search for cakes...",
      "Search for gifts...",
      "Search for flowers...",
      "Search for toys...",
      "Search for celebration items...",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            style: const TextStyle(fontSize: 16),
            onSubmitted: (query) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsPage(query: query),
                ),
              );
            },
            decoration: InputDecoration(
              hintText: "",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 48,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Animated hint centered in TextField
          Positioned.fill(
            left: 48, // space for prefix icon
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedTextKit(
                  animatedTexts:
                      hints
                          .map(
                            (text) => TyperAnimatedText(
                              text,
                              textStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700, // slightly darker
                              ),
                              speed: const Duration(milliseconds: 60),
                            ),
                          )
                          .toList(),
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1500),
                  isRepeatingAnimation: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategorySection() {
    if (categories.isEmpty) return const SizedBox();
    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: _buildCategoryPairs(categories)),
      ),
    );
  }

  List<Widget> _buildCategoryPairs(List<Category> categories) {
    final List<Widget> pairs = [];
    final int half = (categories.length / 2).ceil();

    for (int i = 0; i < half; i++) {
      final top = categories[i];
      final bottom =
          (i + half < categories.length) ? categories[i + half] : null;

      pairs.add(
        Container(
          width: 90,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCategoryItem(top),
              const SizedBox(height: 12),
              if (bottom != null) buildCategoryItem(bottom),
            ],
          ),
        ),
      );
    }

    return pairs;
  }

  Widget buildCategoryItem(Category category) {
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
              radius: 33,
              backgroundImage: NetworkImage(category.imageUrl),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredProducts.length,
            padding: const EdgeInsets.only(left: 16),
            itemBuilder: (context, index) {
              final productData = featuredProducts[index];
              return ProductCard(
                productData: productData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProductDetailPage(productData: productData),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget newArrivalsSection() {
    if (newArrivals.isEmpty) return const SizedBox(); // Or show placeholder

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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: newArrivals.length,
            itemBuilder: (context, index) {
              final productData = newArrivals[index];

              return ProductCard(
                productData: productData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProductDetailPage(productData: productData),
                    ),
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
    if (youMayAlsoLikeProducts.isEmpty) return const SizedBox();

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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: youMayAlsoLikeProducts.length,
            itemBuilder: (context, index) {
              final productData = youMayAlsoLikeProducts[index];

              return ProductCard(
                productData: productData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProductDetailPage(productData: productData),
                    ),
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
    if (appReviews.isEmpty) return const SizedBox();

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
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            itemCount: appReviews.length,
            itemBuilder: (context, index) {
              final data = appReviews[index];
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
