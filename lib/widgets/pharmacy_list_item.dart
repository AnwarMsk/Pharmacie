import 'package:flutter/material.dart';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:dwaya_app/screens/pharmacy/pharmacy_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/favorites_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A widget that displays a single pharmacy item in a list with image, details, and favorite button
class PharmacyListItem extends StatelessWidget {
  final Pharmacy pharmacy;
  const PharmacyListItem({super.key, required this.pharmacy});

  /// Formats the distance value into a human-readable string
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
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: pharmacy.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: pharmacy.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: lightGrey,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: lightGrey,
                            child: Icon(
                              Icons.image_not_supported,
                              color: darkGrey.withAlpha(150),
                              size: 30,
                            ),
                          ),
                          memCacheWidth: 120,
                          memCacheHeight: 120,
                          cacheKey: 'pharmacy_${pharmacy.id}_thumb',
                        )
                      : Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Consumer<FavoritesProvider>(
                          builder: (context, favoritesProvider, child) {
                            final isFav = favoritesProvider.isFavorite(pharmacy.id);
                            final isLoggedIn = favoritesProvider.isLoggedIn;
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isLoggedIn ? (isFav ? Colors.redAccent : Colors.grey) : Colors.grey[300],
                                size: 22,
                              ),
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
                    Row(
                      children: [
                        Text(
                          _formatDistance(pharmacy.distance),
                          style: const TextStyle(fontSize: 13, color: darkGrey),
                        ),
                        if (pharmacy.rating != null) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${pharmacy.rating!.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12, color: darkGrey),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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