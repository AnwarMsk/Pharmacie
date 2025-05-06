import 'package:flutter/material.dart';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:dwaya_app/screens/pharmacy/pharmacy_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/favorites_provider.dart';

class PharmacyListItem extends StatelessWidget {
  final Pharmacy pharmacy;

  const PharmacyListItem({super.key, required this.pharmacy});

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PharmacyDetailScreen(pharmacy: pharmacy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Placeholder Image
              // CircleAvatar(
              //   radius: 30,
              //   backgroundColor: lightGrey,
              //   child: Icon(
              //     Icons.local_pharmacy_outlined,
              //     color: darkGrey.withAlpha(150),
              //     size: 30,
              //   ),
              // ),
              // Display Actual Image or Placeholder
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect( // Clip the image to be rounded
                  borderRadius: BorderRadius.circular(8.0),
                  child: pharmacy.imageUrl.isNotEmpty
                      ? Image.network(
                          pharmacy.imageUrl,
                          fit: BoxFit.cover,
                          // Loading Builder
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child; // Image loaded
                            return Container(
                              color: lightGrey,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          // Error Builder
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: lightGrey,
                              child: Icon(
                                Icons.image_not_supported,
                                color: darkGrey.withAlpha(150),
                                size: 30,
                              ),
                            );
                          },
                        )
                      : Container( // Placeholder if URL is empty
                          color: lightGrey,
                          child: Icon(
                            Icons.local_pharmacy_outlined,
                            color: darkGrey.withAlpha(150),
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              // Pharmacy Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row for Name and Favorite Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expanded name to prevent overflow issues
                        Expanded(
                          child: Text(
                            pharmacy.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Favorite Button (consume provider)
                        Consumer<FavoritesProvider>(
                          builder: (context, favoritesProvider, child) {
                            final isFav = favoritesProvider.isFavorite(pharmacy.id);
                            final isLoggedIn = favoritesProvider.isLoggedIn;
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isLoggedIn ? (isFav ? Colors.redAccent : Colors.grey) : Colors.grey[300], // Dim if logged out
                                size: 22, // Adjust size as needed
                              ),
                              // Disable onPressed if not logged in
                              onPressed: isLoggedIn
                                  ? () {
                                    favoritesProvider.toggleFavorite(pharmacy.id);
                                  }
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pharmacy.address,
                      style: const TextStyle(fontSize: 13, color: darkGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDistance(pharmacy.distance),
                      style: const TextStyle(fontSize: 13, color: darkGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Open Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
