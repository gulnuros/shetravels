import 'package:flutter/material.dart';
import 'package:shetravels/gallery/data/controller/gallery_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class GallerySection extends ConsumerWidget {
  const GallerySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryAsync = ref.watch(galleryImagesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Our Gallery",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          galleryAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error loading gallery: $e'),
            data:
                (images) =>
                    images.isEmpty
                        ? const Text("No images available.")
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: images.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final img = images[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    img.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (ctx, _, __) =>
                                            const Icon(Icons.broken_image),
                                    loadingBuilder: (ctx, child, progress) {
                                      return progress == null
                                          ? child
                                          : const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        img.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }
}
