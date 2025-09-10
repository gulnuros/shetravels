
  import 'package:flutter/material.dart';

Center loadingEventWidget() {
    return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Loading events...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
  }

