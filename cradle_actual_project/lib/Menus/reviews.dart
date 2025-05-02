// Front-End Developer: Ana Marie Ramos

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reviews App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Roboto',
      ),
      home: ReviewsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ReviewsPage extends StatelessWidget {
  final List<Map<String, dynamic>> reviews = [
    {
      'username': 'Cheese Pimiento Revisa',
      'date': 'July 13, 2024',
      'text':
          'Iniisip ko kung bakit ganito ang langit nilay ako sayo. Hindi ko matanggap mahirap magpagpaga Na ako\'y hindi bigo...',
    },
    {
      'username': 'Cheese Pimiento Revisa',
      'date': 'July 13, 2024',
      'text':
          'Iniisip ko kung bakit ganito ang langit nilay ako sayo. Hindi ko matanggap mahirap magpagpaga Na ako\'y hindi bigo...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5EDF8), // light purple background
      body: SafeArea(
        child: Column(
          children: [
            // AppBar Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, size: 24),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Reviews',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24), // balance spacing
                  ],
                ),
              ),
            ),
            // Rating Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(
                    '4.3',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Row(
                    children: List.generate(5, (index) {
                      if (index == 3) {
                        return Icon(Icons.star,
                            color: Colors.purple, size: 24); // 4th star purple
                      } else {
                        return Icon(Icons.star_border,
                            color: Colors.grey, size: 24);
                      }
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Divider(),
            // Review List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => Divider(height: 32),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['username'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              review['date'],
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              review['text'],
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
