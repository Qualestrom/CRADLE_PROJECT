import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apartment Listings',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ApartmentListings(),
    );
  }
}

class ApartmentListings extends StatefulWidget {
  const ApartmentListings({super.key});

  @override
  State<ApartmentListings> createState() => _ApartmentListingsState();
}

class _ApartmentListingsState extends State<ApartmentListings> {
  String? _typeFilter;
  String? _contractFilter;
  String? _genderFilter;
  String? _streetFilter;
  RangeValues _priceRange = const RangeValues(0, 10000);

  final apartmentData = [
    {
      'imageUrl':
          'https://pix1.agoda.net/hotelimages/440/4408571/4408571_18013002210061390098.jpg',
      'title': 'ABC Apartment',
      'price': '₱2,000.00 / Month',
      'rating': '4.5'
    },
    {
      'imageUrl':
          'https://movetoasia.com/wp-content/uploads/2021/04/rent-apartment-philippines-expatriate.jpg',
      'title': 'ABC Bedspace',
      'price': '₱2,500.00 / Month',
      'rating': '4.8'
    },
    {
      'imageUrl':
          'https://th.bing.com/th/id/OIP.WdPkaGsLAWfhzloA140BvQHaEK?w=1920&h=1080&rs=1&pid=ImgDetMain',
      'title': 'Skyline Lofts',
      'price': '₱1,800.00 / Month',
      'rating': '4.2'
    },
  ];

  void toggleMenu() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFede9f3),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: toggleMenu,
            ),
            const Expanded(
              child: Center(
                child: Text("Home", style: TextStyle(color: Colors.black87)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.grey),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
      ),
      drawer: buildMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (var apartment in apartmentData) buildListing(apartment),
          ],
        ),
      ),
    );
  }

  Widget buildMenu() {
    return Drawer(
      child: Container(
        color: const Color(0xFFede9f3),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  "CRADLE",
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Bookmarks"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter filterSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text("Filters",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Type",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...["Apartment", "Bedspace"]
                        .map((type) => RadioListTile<String>(
                              title: Text(type),
                              value: type,
                              groupValue: _typeFilter,
                              onChanged: (String? value) =>
                                  filterSetState(() => _typeFilter = value),
                            )),
                    const SizedBox(height: 15),
                    const Text("Contract",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...["No contract", "With contract"]
                        .map((contract) => RadioListTile<String>(
                              title: Text(contract),
                              value: contract,
                              groupValue: _contractFilter,
                              onChanged: (String? value) =>
                                  filterSetState(() => _contractFilter = value),
                            )),
                    const SizedBox(height: 15),
                    const Text("Gender",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...["Male", "Female", "Mixed"]
                        .map((gender) => RadioListTile<String>(
                              title: Text(gender),
                              value: gender,
                              groupValue: _genderFilter,
                              onChanged: (String? value) =>
                                  filterSetState(() => _genderFilter = value),
                            )),
                    const SizedBox(height: 15),
                    const Text("Street",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Universe St.',
                      ),
                      value: _streetFilter,
                      items: ['Universe St.', 'Galaxy Ave', 'Cosmic Rd']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) =>
                          filterSetState(() => _streetFilter = newValue),
                    ),
                    const SizedBox(height: 15),
                    const Text("Price Range",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      labels: RangeLabels(
                        '₱${_priceRange.start.round()}',
                        '₱${_priceRange.end.round()}',
                      ),
                      onChanged: (RangeValues values) =>
                          filterSetState(() => _priceRange = values),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Clear"),
                          onPressed: () => filterSetState(() {
                            _typeFilter = null;
                            _contractFilter = null;
                            _genderFilter = null;
                            _streetFilter = null;
                            _priceRange = const RangeValues(0, 10000);
                          }),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          child: const Text("Save"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildListing(Map<String, String> apartment) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(apartment['imageUrl']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.8),
                    child: Text(
                      apartment['title']!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.more_vert, color: Colors.grey),
                ),
                const Positioned(
                  bottom: 10,
                  right: 10,
                  child: Icon(Icons.bookmark_border, color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(apartment['title']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Apartment",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(apartment['price']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        const Icon(Icons.star, color: Colors.yellow),
                      const Icon(Icons.star_half, color: Colors.yellow),
                      const SizedBox(width: 5),
                      Text(apartment['rating']!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Cozy apartment with modern amenities, great location near public transportation and shops.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
