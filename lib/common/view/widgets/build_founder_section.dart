import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/common/data/founder_provider.dart';
import 'package:shetravels/common/data/models/founder_message.dart';

class FounderSection extends ConsumerStatefulWidget {
  const FounderSection({super.key});

  @override
  ConsumerState<FounderSection> createState() => _FounderSectionState();
}

class _FounderSectionState extends ConsumerState<FounderSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(founderProvider.notifier).loadFounderMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final founderState = ref.watch(founderProvider);

    if (founderState.isLoading) {
      return _buildLoadingState();
    }

    if (founderState.error != null) {
      return _buildErrorState(founderState.error!);
    }

    if (founderState.founderMessages.isEmpty) {
      return _buildEmptyState();
    }

    final founderMessage = founderState.founderMessages.first;
    return _buildFounderSection(context, founderMessage);
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade300),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error loading founder message',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No founder message available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFounderSection(
    BuildContext context,
    FounderMessage founderMessage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return isMobile
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      founderMessage.imageUrl,
                      fit: BoxFit.cover,
                      height: 240,
                      width: double.infinity,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: Colors.grey,
                            height: 200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        founderMessage.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        softWrap: true,
                        founderMessage.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        softWrap: true,
                        founderMessage.message,
                        style: GoogleFonts.poppins(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      founderMessage.imageUrl,
                      fit: BoxFit.cover,
                      height: 320,
                      width: 320,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: Colors.grey,
                            height: 320,
                            width: 320,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                    ),
                  ),
                  SizedBox(width: 40),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          founderMessage.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade300,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        Text(
                          softWrap: true,
                          founderMessage.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          softWrap: true,
                          founderMessage.message,
                          style: GoogleFonts.poppins(fontSize: 16, height: 1.5),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                ],
              );
        },
      ),
    );
  }
}
