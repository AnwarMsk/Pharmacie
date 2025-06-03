import 'package:flutter/material.dart';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/utils/colors.dart';
class PharmacyDetailScreen extends StatelessWidget {
  final Pharmacy pharmacy;
  const PharmacyDetailScreen({super.key, required this.pharmacy});
  String _formatDistance(double? meters) {
    if (meters == null) {
      return 'N/A';
    }
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: primaryGreen,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white70,
                child: Icon(Icons.arrow_back, color: black),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                pharmacy.name,
                style: const TextStyle(color: white, fontSize: 16.0),
              ),
              background: pharmacy.imageUrl.isNotEmpty
                  ? Image.network(
                      pharmacy.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: mediumGrey,
                        child: const Center(
                          child: Icon(Icons.storefront, size: 100, color: lightGrey),
                        ),
                      ),
                    )
                  : Container(
                      color: mediumGrey,
                      child: const Center(
                        child: Icon(Icons.storefront, size: 100, color: lightGrey),
                      ),
                    ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy
                                  .name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pharmacy.address} (${_formatDistance(pharmacy.distance)})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              pharmacy.isOpen
                                  ? primaryGreen.withAlpha(26)
                                  : Colors.red.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pharmacy.isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: pharmacy.isOpen ? primaryGreen : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  const Text(
                    'Working Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: darkGrey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mon - Fri: 09:00 AM - 6:00 PM',
                          style: TextStyle(fontSize: 14, color: darkGrey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: darkGrey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sat - Sun: Closed',
                          style: TextStyle(fontSize: 14, color: darkGrey),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This pharmacy offers a wide range of prescription and over-the-counter medications. Pharmacist consultation available. Delivery services may be offered.',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}