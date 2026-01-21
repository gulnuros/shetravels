import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shetravels/admin/data/models/memory.dart';


class MemoriesSection extends StatefulWidget {
  const MemoriesSection({super.key});

  @override
  State<MemoriesSection> createState() => _MemoriesSectionState();
}

class _MemoriesSectionState extends State<MemoriesSection> {
  List<Memory> _memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemoriesFromFirestore();
  }

  Future<void> _loadMemoriesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('memories').get();
      final memoriesList = snapshot.docs.map((doc) => Memory.fromFirestore(doc)).toList();

      setState(() {
        _memories = memoriesList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading memories: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMemoryCard(BuildContext context, Memory memory) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              memory.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.image_not_supported)),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[100],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  memory.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Memories & Highlights",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Relive inspiring moments—shared with sisterhood, joy, and exploration.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 300,
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.pink.shade100))
                : _memories.isEmpty
                    ? const Center(child: Text("No memories available yet."))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _memories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return _buildMemoryCard(context, _memories[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
