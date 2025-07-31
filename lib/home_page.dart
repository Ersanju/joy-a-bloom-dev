import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joy_a_bloom_dev/pages/account_page/account_page.dart';
import 'package:joy_a_bloom_dev/pages/account_page/edit_profile_page.dart';
import 'package:joy_a_bloom_dev/pages/authentication/app_auth_provider.dart';
import 'package:joy_a_bloom_dev/pages/authentication/login_page.dart';
import 'package:joy_a_bloom_dev/pages/cart/cart_page.dart';
import 'package:joy_a_bloom_dev/pages/category/category_page.dart';
import 'package:joy_a_bloom_dev/pages/home/chocolate_product_detail_page.dart';
import 'package:joy_a_bloom_dev/pages/home/products_by_category_grid_page.dart';
import 'package:joy_a_bloom_dev/pages/home/search_results_page.dart';
import 'package:joy_a_bloom_dev/pages/product_detail_page.dart';
import 'package:joy_a_bloom_dev/utils/app_util.dart';
import 'package:joy_a_bloom_dev/utils/wishlist_provider.dart';
import 'package:joy_a_bloom_dev/widgets/cake_product_card.dart';
import 'package:joy_a_bloom_dev/widgets/chocolate_product_card.dart';
import 'package:provider/provider.dart';

import 'models/category.dart';
import 'models/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool hasInternet = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool isHomeLoading = true;
  List<Category> categories = [];
  List<String> bannerImages = [];
  List<Map<String, dynamic>> featuredProducts = [];
  List<Map<String, dynamic>> newArrivals = [];
  List<Map<String, dynamic>> chocolates = [];
  List<Map<String, dynamic>> youMayAlsoLikeProducts = [];
  List<Map<String, dynamic>> appReviews = [];
  String _locationText = 'Fetching location...';
  String _pinCode = '';
  Timer? _timer;

  bool isLoadingBanners = true;
  Map<String, int> cartQuantities = {};
  Map<String, int> variantQuantities = {}; // key: productId_sku
  final TextEditingController _searchController = TextEditingController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _startConnectivityListener();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && bannerImages.isNotEmpty) {
        final nextPage =
            (_pageController.page!.round() + 1) % bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final realInternet = await _hasRealInternet();
      setState(() {
        hasInternet = realInternet;
      });

      if (realInternet && categories.isEmpty) {
        _loadInitialData();
        _fetchBannerImages();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => isHomeLoading = true);
    await Future.wait([_loadAllHomeData(), _fetchLocation()]);
    _preCacheHomeImages();
    setState(() => isHomeLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false; // Prevent app from closing
        }
        return true; // Allow app to close from Home
      },
      child: Scaffold(
        appBar: _currentIndex == 0 ? buildAppBar() : null,
        body:
            hasInternet
                ? _pages[_currentIndex]
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon/no_internet.gif',
                        width: 400,
                        height: 450,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final realInternet = await _hasRealInternet();
                          if (realInternet) {
                            setState(() {
                              hasInternet = true;
                            });
                            _loadInitialData();
                            _fetchBannerImages();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No internet connection. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

        bottomNavigationBar: buildBottomNavigationBar(),
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final userData = auth.userData;
    final isLoggedIn = user != null;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
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
      actions: [
        if (!isLoggedIn)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text("Login / Signup"),
          )
        else
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            userData?['profileImageUrl'] != null &&
                                    userData!['profileImageUrl']
                                        .toString()
                                        .isNotEmpty
                                ? CachedNetworkImageProvider(
                                  userData['profileImageUrl'],
                                )
                                : null,
                        backgroundColor: Colors.grey[300],
                        child:
                            userData?['profileImageUrl'] == null ||
                                    userData!['profileImageUrl']
                                        .toString()
                                        .isEmpty
                                ? const Icon(Icons.person, size: 16)
                                : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData?['name']?.split(' ').first ?? "User",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
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
          buildSearchBar(
            context,
            _searchController,
            () => _handleSearch(context),
          ),
          const SizedBox(height: 10),
          buildCategorySection(),
          buildBannerSlider(),
          SizedBox(height: 10),
          featuredOffersSection(context),
          const SizedBox(height: 10),
          chocolateBarSection(chocolates),
          SizedBox(height: 10),
          newArrivalsSection(context),
          SizedBox(height: 10),
          youMayAlsoLikeSection(context),
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

      final categoryQuery = FirebaseFirestore.instance.collection('categories');
      final nullSnapshotFuture =
          categoryQuery
              .where('active', isEqualTo: true)
              .where('categoryId', isNull: true)
              .orderBy('priority')
              .get();
      final emptySnapshotFuture =
          categoryQuery
              .where('active', isEqualTo: true)
              .where('categoryId', isEqualTo: '')
              .orderBy('priority')
              .get();

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
      final chocolatesFuture =
          FirebaseFirestore.instance
              .collection('products')
              .where('categoryId', isEqualTo: 'cat_chocolate')
              .limit(10)
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

      final results = await Future.wait([
        nullSnapshotFuture,
        emptySnapshotFuture,
        bannerFuture,
        featuredFuture,
        chocolatesFuture,
        newArrivalsFuture,
        youMayAlsoLikeFuture,
        appReviewsFuture,
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs];
      final seen = <String>{};
      final fetchedCategories =
          allDocs
              .where((doc) => seen.add(doc.id))
              .map((doc) => Category.fromMap(doc.id, doc.data()))
              .toList();

      setState(() {
        categories = fetchedCategories;
        bannerImages =
            results[2].docs.map((d) => d['imageUrl'] as String).toList();
        featuredProducts = results[3].docs.map((d) => d.data()).toList();
        isHomeLoading = false;
        chocolates = results[4].docs.map((d) => d.data()).toList();
        newArrivals = results[5].docs.map((d) => d.data()).toList();
        youMayAlsoLikeProducts = results[6].docs.map((d) => d.data()).toList();
        appReviews = results[7].docs.map((d) => d.data()).toList();
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _preCacheHomeImages(); // precache happens after smooth delay
    } catch (e) {
      debugPrint("Error loading homepage data: $e");
      setState(() => isHomeLoading = false);
    }
  }

  void _preCacheHomeImages() {
    final context = this.context;

    final allImageUrls =
        [
          ...bannerImages,
          ...featuredProducts.map((p) => p['imageUrl'] as String? ?? ''),
          ...chocolates.map((p) => p['imageUrl'] as String? ?? ''),
          ...newArrivals.map((p) => p['imageUrl'] as String? ?? ''),
          ...youMayAlsoLikeProducts.map((p) => p['imageUrl'] as String? ?? ''),
        ].where((url) => url.isNotEmpty).toSet(); // remove duplicates & empties

    for (final url in allImageUrls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = 'Location services disabled';
        _pinCode = '';
      });
      // Skip provider update in error case
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = 'Permission denied';
          _pinCode = '';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationText = 'Permission permanently denied';
        _pinCode = '';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationText = '${place.locality}, ${place.administrativeArea}';
        final pinCode = place.postalCode ?? '';

        setState(() {
          _locationText = locationText;
          _pinCode = pinCode;
        });
      } else {
        setState(() {
          _locationText = 'Location not found';
          _pinCode = '';
        });
        // You may optionally skip update here
      }
    } catch (e) {
      setState(() {
        _locationText = 'Error fetching location';
        _pinCode = '';
      });
      // You may optionally skip update here
    }
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

      // Precache images after they're set
      for (var url in bannerImages) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    } catch (e) {
      debugPrint("Error loading banners: $e");
      setState(() {
        isLoadingBanners = false;
      });
    }
  }

  List<Widget> get _pages => [
    buildHomeContent(),
    CategoryPage(),
    CartPage(),
    AccountPage(),
  ];

  void _handleSearch(BuildContext context) {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least 3 characters")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultsPage(query: query)),
    );
  }

  Widget buildSearchBar(
    BuildContext context,
    TextEditingController controller,
    VoidCallback onSearch,
  ) {
    final List<String> hints = [
      "  Search for cakes...",
      "  Search for gifts...",
      "  Search for flowers...",
      "  Search for toys...",
      "  Search for celebration items...",
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        bool isTyping = controller.text.isNotEmpty;

        controller.addListener(() {
          setState(() {});
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "",
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 22,
                  ),
                  suffixIcon:
                      isTyping
                          ? Padding(
                            padding: const EdgeInsets.only(
                              right: 8.0,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                // Change to your desired background
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // Rounded background
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.black,
                                ),
                                // Icon color
                                onPressed: onSearch,
                              ),
                            ),
                          )
                          : null,
                  prefixIcon: isTyping ? null : const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (!isTyping)
                Positioned.fill(
                  left: 48,
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
                                      color: Colors.grey.shade700,
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
      },
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
              backgroundImage: CachedNetworkImageProvider(category.imageUrl),
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
                image: CachedNetworkImageProvider(bannerImages[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget chocolateBarSection(List<Map<String, dynamic>> chocolates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Shop For Chocolate Bars",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: chocolates.length,
            itemBuilder: (context, index) {
              final productData = chocolates[index];
              final chocolateAttr =
                  productData['extraAttributes']?['chocolateAttribute'];
              final variant = (chocolateAttr?['variants'] as List?)?.first;
              if (variant == null) return const SizedBox.shrink();

              final product = Product.fromJson(productData);

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 4, // First item has more left padding
                  right:
                      index == chocolates.length - 1
                          ? 16
                          : 8, // Last item right pad
                ),
                child: ChocolateProductCard(
                  productData: productData,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChocolateProductDetailPage(
                              productId: product.id,
                            ),
                      ),
                    );
                  },
                  onVariantTap:
                      () => ChocolateProductCard.showVariantsBottomSheet(
                        context,
                        product,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget featuredOffersSection(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

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
              final productId = productData['id'];

              return CakeProductCard(
                productData: productData,
                isWishlisted: wishlistProvider.isWishlisted(productId),
                onWishlistToggle: () async {
                  final isLoggedIn = await AppUtil.ensureLoggedInGlobal(
                    context,
                  );
                  if (!isLoggedIn) return;

                  wishlistProvider.toggleWishlist(productId);
                },
                onTap: () {
                  if (productId.startsWith('sub_cat_cake')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(productId: productId),
                      ),
                    );
                  } else if (productId.startsWith('sub_cat_chocolate')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChocolateProductDetailPage(
                              productId: productId,
                            ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget newArrivalsSection(BuildContext context) {
    if (newArrivals.isEmpty) return const SizedBox();

    final wishlistProvider = Provider.of<WishlistProvider>(context);

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
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: newArrivals.length,
            itemBuilder: (context, index) {
              final productData = newArrivals[index];
              final productId = productData['id'];
              final categoryId = productData['categoryId'];

              final Widget card =
                  categoryId == 'cat_chocolate'
                      ? ChocolateProductCard(
                        productData: productData,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChocolateProductDetailPage(
                                    productId: productId,
                                  ),
                            ),
                          );
                        },
                        onVariantTap: () {
                          final product = Product.fromJson(productData);
                          ChocolateProductCard.showVariantsBottomSheet(
                            context,
                            product,
                          );
                        },
                      )
                      : CakeProductCard(
                        productData: productData,
                        isWishlisted: wishlistProvider.isWishlisted(productId),
                        onWishlistToggle: () async {
                          final isLoggedIn = await AppUtil.ensureLoggedInGlobal(
                            context,
                          );
                          if (!isLoggedIn) return;
                          setState(() {
                            wishlistProvider.toggleWishlist(productId);
                          });
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ProductDetailPage(productId: productId),
                            ),
                          );
                        },
                      );

              return Padding(
                padding: EdgeInsets.only(right: 8), // uniform spacing
                child: SizedBox(width: 120, height: 210, child: card),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget youMayAlsoLikeSection(BuildContext context) {
    if (youMayAlsoLikeProducts.isEmpty) return const SizedBox();

    final wishlistProvider = Provider.of<WishlistProvider>(context);

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
              final productId = productData['id'];

              return CakeProductCard(
                productData: productData,
                isWishlisted: wishlistProvider.isWishlisted(productId),
                onWishlistToggle: () async {
                  final isLoggedIn = await AppUtil.ensureLoggedInGlobal(
                    context,
                  );
                  if (!isLoggedIn) return;

                  wishlistProvider.toggleWishlist(productId);
                },
                onTap: () {
                  if (productId.startsWith('sub_cat_cake')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(productId: productId),
                      ),
                    );
                  } else if (productId.startsWith('sub_cat_chocolate')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChocolateProductDetailPage(
                              productId: productId,
                            ),
                      ),
                    );
                  }
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
