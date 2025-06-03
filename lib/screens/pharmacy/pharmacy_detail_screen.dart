import 'package:flutter/material.dart';
import 'package:dwaya_app/models/pharmacy.dart';
import 'package:dwaya_app/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:dwaya_app/providers/favorites_provider.dart';
import 'package:dwaya_app/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dwaya_app/providers/app_navigation_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dwaya_app/providers/location_provider.dart';
import 'package:dwaya_app/providers/directions_provider.dart';
class PharmacyDetailScreen extends StatefulWidget {
  final Pharmacy pharmacy;
  const PharmacyDetailScreen({super.key, required this.pharmacy});
  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}
class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final bool isFavorite = favoritesProvider.isFavorite(widget.pharmacy.id);
    final bool isLoggedIn = authProvider.currentUser != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacy.name),
        backgroundColor: primaryGreen,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : white,
            ),
            tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: !isLoggedIn ? null : () {
              favoritesProvider.toggleFavorite(widget.pharmacy.id);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.pharmacy.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: widget.pharmacy.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator(color: primaryGreen)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.storefront, color: Colors.grey, size: 50),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                widget.pharmacy.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(widget.pharmacy.isOpen ? 'Open' : 'Closed'),
                    backgroundColor: widget.pharmacy.isOpen ? Colors.green.shade100 : Colors.red.shade100,
                    labelStyle: TextStyle(
                      color: widget.pharmacy.isOpen ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  if (widget.pharmacy.rating != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          widget.pharmacy.rating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        if (widget.pharmacy.userRatingsTotal != null)
                         Text(
                           ' (${widget.pharmacy.userRatingsTotal})',
                           style: TextStyle(fontSize: 14, color: Colors.grey),
                         ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on_outlined, widget.pharmacy.address),
              const SizedBox(height: 8),
              if (widget.pharmacy.distance != null)
                _buildDetailRow(Icons.directions_walk_outlined, '${(widget.pharmacy.distance! / 1000).toStringAsFixed(1)} km away'),
              const SizedBox(height: 8),
              if (widget.pharmacy.phoneNumber != null)
                _buildDetailRow(Icons.phone_outlined, widget.pharmacy.phoneNumber!),
              const SizedBox(height: 8),
              if (widget.pharmacy.website != null)
                 _buildDetailRow(Icons.language_outlined, widget.pharmacy.website!),
              const SizedBox(height: 8),
              if (widget.pharmacy.openingHours != null && widget.pharmacy.openingHours!.isNotEmpty)
                _buildOpeningHours(context, widget.pharmacy.openingHours!),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: darkGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
      ],
    );
  }
  Widget _buildOpeningHours(BuildContext context, List<String> hours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(),
         const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.access_time_outlined, color: darkGrey, size: 20),
            const SizedBox(width: 12),
            Text(
              'Opening Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: hours.map((line) => Text(line, style: TextStyle(fontSize: 14))).toList(),
          ),
        ),
         const SizedBox(height: 12),
         const Divider(),
      ],
    );
  }
  Widget _buildActionButtons(BuildContext context) {
    final pharmacy = widget.pharmacy;
    final locationProvider = context.read<LocationProvider>();
    final bool canCall = pharmacy.phoneNumber != null && pharmacy.phoneNumber!.isNotEmpty;
    final bool canViewWebsite = pharmacy.website != null && pharmacy.website!.isNotEmpty;
    final bool canShowMap = pharmacy.latitude != null && pharmacy.longitude != null;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.spaceAround,
      children: [
        ElevatedButton.icon(
          onPressed: canShowMap
              ? () {
                  final lat = pharmacy.latitude!;
                  final lon = pharmacy.longitude!;
                  context.read<AppNavigationProvider>().focusMapOnLocation(LatLng(lat, lon), pharmacy: pharmacy);
                  Navigator.pop(context);
                }
              : null,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Map'),
          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: white),
        ),
        ElevatedButton.icon(
          onPressed: canCall ? () => _launchUrl('tel:${pharmacy.phoneNumber!}') : null,
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call'),
          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: white),
        ),
        ElevatedButton.icon(
          onPressed: canViewWebsite ? () => _launchUrl(pharmacy.website!) : null,
          icon: const Icon(Icons.web_outlined),
          label: const Text('Website'),
          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: white),
        ),
      ],
    );
  }
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $urlString'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
    } else {
      await launchUrl(url);
    }
  }
}