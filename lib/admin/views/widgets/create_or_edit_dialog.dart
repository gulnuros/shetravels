import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:intl/intl.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shetravels/admin/views/widgets/build_image_preview.dart';
import 'package:shetravels/admin/views/widgets/error_success_snack_bar.dart';
import 'package:shetravels/admin/views/widgets/modern_button.dart';
import 'package:shetravels/admin/views/widgets/modern_textfield.dart';
StatefulBuilder createOrEditDialog(
  Animation<double> animation,
  bool isEditing,
  TextEditingController titleController,
  Event? existingEvent,
  TextEditingController dateController,
  TextEditingController locationController,
  TextEditingController priceController,
  TextEditingController descController,
  TextEditingController slotsController, // 🆕 Added slots controller
  Uint8List? imageBytes,
  String? imageUrl,
  bool isUploading,
  WidgetRef ref,
) {
  // Initialize controllers with existing event data if editing
  if (isEditing && existingEvent != null) {
    final priceInDollars = existingEvent.price / 100.0;
    priceController.text = priceInDollars.toStringAsFixed(2);
    slotsController.text = existingEvent.availableSlots.toString(); // 🆕 Initialize slots
  }

  return StatefulBuilder(
    builder:
        (context, setStateDialog) => AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: animation.value,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screen = MediaQuery.of(context).size;
                    final maxWidth =
                        screen.width >= 900 ? 720.0 : screen.width * 0.92;
                    final maxHeight = screen.height * 0.88;

                    return Container(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.purple.shade50],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            // ===== Header =====
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade600,
                                    Colors.deepPurple.shade700,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isEditing
                                          ? Icons.edit
                                          : Icons.event_available,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      isEditing
                                          ? "Edit Event"
                                          : "Create New Event",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ===== Content =====
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildModernTextField(
                                      controller: titleController,
                                      label: "Event Title",
                                      icon: Icons.title,
                                      hint: "Enter event name",
                                    ),
                                    const SizedBox(height: 20),

                                    // Date (Calendar Picker)
                                    GestureDetector(
                                      onTap: () async {
                                        DateTime? initialDate = DateTime.now();
                                        if (isEditing &&
                                            existingEvent!.date.isNotEmpty) {
                                          try {
                                            initialDate = DateFormat.yMMMd()
                                                .parse(existingEvent.date);
                                          } catch (e) {
                                            initialDate = DateTime.now();
                                          }
                                        }

                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: initialDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                          helpText: 'Select event date',
                                          builder: (context, child) {
                                            return Center(
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 400,
                                                    ),
                                                child: child!,
                                              ),
                                            );
                                          },
                                        );
                                        if (pickedDate != null) {
                                          setStateDialog(() {
                                            dateController
                                                .text = DateFormat.yMMMd()
                                                .format(pickedDate);
                                          });
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: buildModernTextField(
                                          controller: dateController,
                                          label: "Event Date",
                                          icon: Icons.calendar_today,
                                          hint: "Select date",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    buildModernTextField(
                                      controller: locationController,
                                      label: "Location",
                                      icon: Icons.location_on,
                                      hint: "Event venue",
                                    ),
                                    const SizedBox(height: 20),

                                    // 🆕 Price and Slots in a Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: buildModernTextField(
                                            controller: priceController,
                                            label: "Price (USD)",
                                            icon: Icons.attach_money,
                                            hint: "0.00",
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: buildModernTextField(
                                            controller: slotsController,
                                            label: "Available Slots",
                                            icon: Icons.people_outline,
                                            hint: "e.g., 11",
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    buildModernTextField(
                                      controller: descController,
                                      label: "Description",
                                      icon: Icons.description,
                                      hint: "Event details",
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 24),

                                    // ===== Image Upload Section =====
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade50,
                                            Colors.purple.shade50,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.purple.shade200,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Event Image",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Preview
                                          buildImagePreview(
                                            imageBytes,
                                            imageUrl,
                                          ),
                                          const SizedBox(height: 16),

                                          // Buttons
                                          Row(
                                            children: [
                                              Expanded(
                                                child: buildModernButton(
                                                  onPressed:
                                                      isUploading
                                                          ? null
                                                          : () async {
                                                            final picker =
                                                                ImagePicker();
                                                            final picked = await picker
                                                                .pickImage(
                                                                  source:
                                                                      ImageSource
                                                                          .gallery,
                                                                  maxWidth:
                                                                      1024,
                                                                  maxHeight:
                                                                      1024,
                                                                  imageQuality:
                                                                      85,
                                                                );
                                                            if (picked == null)
                                                              return;
                                                            final bytes =
                                                                await picked
                                                                    .readAsBytes();
                                                            setStateDialog(() {
                                                              imageBytes =
                                                                  bytes;
                                                              // Don't clear imageUrl immediately for editing
                                                            });
                                                          },
                                                  icon: Icons.photo_library,
                                                  label: "Select",
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: buildModernButton(
                                                  onPressed:
                                                      isUploading ||
                                                              (imageBytes ==
                                                                      null &&
                                                                  !isEditing)
                                                          ? null
                                                          : () async {
                                                            if (imageBytes !=
                                                                null) {
                                                              setStateDialog(
                                                                () =>
                                                                    isUploading =
                                                                        true,
                                                              );
                                                              final uploadedUrl = await ref
                                                                  .read(
                                                                    eventManagerDashboardProvider,
                                                                  )
                                                                  .uploadImage(
                                                                    bytes:
                                                                        imageBytes,
                                                                  );
                                                              setStateDialog(() {
                                                                isUploading =
                                                                    false;
                                                                if (uploadedUrl !=
                                                                    null) {
                                                                  imageUrl =
                                                                      uploadedUrl;
                                                                  imageBytes =
                                                                      null;
                                                                }
                                                              });
                                                            }
                                                          },
                                                  icon:
                                                      isUploading
                                                          ? null
                                                          : Icons.cloud_upload,
                                                  label:
                                                      isUploading
                                                          ? "Uploading..."
                                                          : "Upload",
                                                  color: Colors.purple,
                                                  isLoading: isUploading,
                                                ),
                                              ),
                                            ],
                                          ),

                                          if (imageUrl != null &&
                                              imageBytes == null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color:
                                                        Colors.green.shade600,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isEditing
                                                        ? "Current image"
                                                        : "Image uploaded successfully!",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.green.shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // ===== Actions =====
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              side: BorderSide(
                                                color: Colors.grey.shade400,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.purple.shade600,
                                                  Colors.deepPurple.shade700,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.purple
                                                      .withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed:
                                                  isUploading
                                                      ? null
                                                      : () async {
                                                        // Validate title
                                                        if (titleController.text
                                                            .trim()
                                                            .isEmpty) {
                                                          showErrorSnackBar(
                                                            "Please enter a title",
                                                            context,
                                                          );
                                                          return;
                                                        }
                                                        
                                                        // Validate date
                                                        if (dateController.text
                                                            .trim()
                                                            .isEmpty) {
                                                          showErrorSnackBar(
                                                            "Please select a date",
                                                            context,
                                                          );
                                                          return;
                                                        }
                                                        
                                                        // Validate image
                                                        if (imageUrl == null) {
                                                          showErrorSnackBar(
                                                            "Please upload an image",
                                                            context,
                                                          );
                                                          return;
                                                        }

                                                        // Validate and parse price
                                                        final priceText =
                                                            priceController.text
                                                                .trim()
                                                                .replaceAll(',', '');
                                                        
                                                        if (priceText.isEmpty) {
                                                          showErrorSnackBar(
                                                            "Please enter a price",
                                                            context,
                                                          );
                                                          return;
                                                        }
                                                        
                                                        final parsedPrice = double.tryParse(priceText);
                                                        if (parsedPrice == null) {
                                                          showErrorSnackBar(
                                                            "Please enter a valid numeric price",
                                                            context,
                                                          );
                                                          return;
                                                        }
                                                        
                                                        if (parsedPrice < 0) {
                                                          showErrorSnackBar(
                                                            "Price cannot be negative",
                                                            context,
                                                          );
                                                          return;
                                                        }

                                                        // 🆕 Validate and parse slots
                                                        final slotsText = slotsController.text.trim();
                                                        if (slotsText.isEmpty) {
                                                          showErrorSnackBar(
                                                            "Please enter the number of available slots",
                                                            context,
                                                          );
                                                          return;
                                                        }
                                                        
                                                        final parsedSlots = int.tryParse(slotsText);
                                                        if (parsedSlots == null) {
                                                          showErrorSnackBar(
                                                            "Please enter a valid number for slots",
                                                            context,
                                                          );
                                                          return;
                                                        }
                                                        
                                                        if (parsedSlots <= 0) {
                                                          showErrorSnackBar(
                                                            "Number of slots must be greater than 0",
                                                            context,
                                                          );
                                                          return;
                                                        }

                                                        final priceInCents = (parsedPrice * 100).round();

                                                        final eventData = Event(
                                                          id: isEditing ? existingEvent!.id : null,
                                                          title: titleController.text.trim(),
                                                          date: dateController.text.trim(),
                                                          description: descController.text.trim(),
                                                          location: locationController.text.trim(),
                                                          price: priceInCents,
                                                          availableSlots: parsedSlots, // 🆕 Include slots
                                                          imageUrl: imageUrl!,
                                                        );

                                                        Navigator.pop(context);

                                                        if (isEditing) {
                                                          await ref
                                                              .read(eventManagerDashboardProvider)
                                                              .editEvent(eventData, context);
                                                        } else {
                                                          await ref
                                                              .read(eventManagerDashboardProvider)
                                                              .addEvent(eventData, context);
                                                        }
                                                      },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                isEditing ? "Update Event" : "Create Event",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
  );
}