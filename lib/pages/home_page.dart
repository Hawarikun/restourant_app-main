import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:restourant_app/data/api/api_service.dart';

import 'package:restourant_app/data/model/restaurant.dart';
import 'package:restourant_app/package/provider/globalProvider.dart';
import 'package:restourant_app/pages/detail_restaurant.dart';
import 'package:restourant_app/style/style.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchValue = "";

  // restaurant
  late Future<List<Restaurant>> restaurant;

  /// restaurant List
  List<Restaurant> restaurantList = [];

  // restaurant list after search
  List<Restaurant> searchRestaurant = [];

  // Restaurant by rating
  List<Restaurant> byRating = [];

  @override
  void initState() {
    restaurant = ApiService().getAllRestaurant();
    super.initState();
    fetchAndParseRestaurantList();
  }

  // filter restaurant by search
  List<Restaurant> filterRestaurants(
      List<Restaurant> restaurants, String searchValue) {
    return restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(searchValue.toLowerCase());
    }).toList();
  }

  // call data restaurant
  Future fetchAndParseRestaurantList() async {
    try {
      restaurantList = await restaurant;

      List<Restaurant> sortByRating = List.from(restaurantList);
      sortByRating.sort((a, b) => b.rating.compareTo(a.rating));

      List<Restaurant> top5Restaurants = sortByRating.take(5).toList();

      setState(() {
        restaurantList;
        searchRestaurant = filterRestaurants(restaurantList, searchValue);
        byRating = top5Restaurants;
      });
    } catch (error) {
      print("e : $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EasySearchBar(
        title: const Text(
          "Restaurant",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        searchHintText: "search restourant",
        onSearch: (value) => setState(
          () {
            searchValue = value;
            searchRestaurant = filterRestaurants(restaurantList, searchValue);
          },
        ),
      ),

      // Call Data Futere
      body: Consumer<GlobalProvider>(
        builder: (context, globalProvider, child) {
          if (globalProvider.connectionStatus == ConnectivityResult.none) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded),
                    const SizedBox(height: 5),
                    const Text('No connection'),
                    const SizedBox(height: 5),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text("refresh"))
                  ],
                ),
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                await globalProvider.initConnectivity();
                setState(() {});
              },
              child: FutureBuilder(
                future: restaurant,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Text('No data available');
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //  ketika searchValue kosong tampilkan
                          if (searchValue.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "Recommendation for you",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),

                          //  ketika searchValue kosong tampilkan
                          if (searchValue.isEmpty)
                            _corouselSliderCostum(context, byRating),

                          //  ketika searchValue kosong tampilkan
                          if (searchValue.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                "Explore Restaurant",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),

                          //  ketika searchValue kosong ataupun tidak kosong tampilkan
                          if (searchValue.isEmpty || searchValue.isNotEmpty)
                            AnimationLimiter(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: searchRestaurant.length,
                                itemBuilder: (context, index) {
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 800),
                                    child: SlideAnimation(
                                      verticalOffset: 100.0,
                                      child: FadeInAnimation(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          child: _buildRestaurantItem(
                                            context,
                                            searchRestaurant[index],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }
}

Widget _corouselSliderCostum(BuildContext context, List data) {
  final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

  return CarouselSlider(
    options: CarouselOptions(
      aspectRatio: 2.3,
      enlargeCenterPage: true,
      initialPage: 2,
      autoPlay: true,
    ),
    items: data.map((restaurant) {
      return Builder(
        builder: (BuildContext context) {
          return InkWell(
            onTap: () {
              globalProvider.setDetailRestaurantID(restaurant.id.toString());
              print(restaurant.id);
              Navigator.pushNamed(
                context,
                RestaurantDetail.routeName,
                arguments: restaurant,
              );
            },
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://restaurant-api.dicoding.dev/images/medium/${restaurant.pictureId}'),
                      fit: BoxFit.fill,
                      onError: (ctx, error) =>
                          const Center(child: Icon(Icons.error)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            restaurant.name,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Star review
                      Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color.fromARGB(211, 224, 224, 224),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: starColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                restaurant.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }).toList(),
  );
}

//  Build Restauran Content
Widget _buildRestaurantItem(BuildContext context, Restaurant restaurant) {
  final globalProvider = Provider.of<GlobalProvider>(context, listen: false);
  return Card(
    surfaceTintColor: Colors.white,
    elevation: 2,
    child: ListTile(
      leading: Hero(
        tag: restaurant.pictureId,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            "https://restaurant-api.dicoding.dev/images/small/${restaurant.pictureId}",
            width: 75,
            fit: BoxFit.fill,
            errorBuilder: (ctx, error, _) =>
                const Center(child: Icon(Icons.error)),
          ),
        ),
      ),

      // restaurant Name
      title: Text(
        restaurant.name,
        maxLines: 1,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // restaurant Location
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 12,
              ),
              const SizedBox(width: 5),
              Text(
                restaurant.city,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          // Restaurant Rating
          Row(
            children: [
              const Icon(
                Icons.star,
                size: 12,
                color: starColor,
              ),
              const SizedBox(width: 5),
              Text(
                restaurant.rating.toString(),
                style: const TextStyle(fontSize: 12),
              )
            ],
          ),
        ],
      ),
      onTap: () {
        globalProvider.setDetailRestaurantID(restaurant.id);
        Navigator.pushNamed(
          context,
          RestaurantDetail.routeName,
          arguments: restaurant,
        );
      },
    ),
  );
}
