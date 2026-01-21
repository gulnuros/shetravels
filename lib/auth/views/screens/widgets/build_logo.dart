import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shetravels/utils/colors.dart';
import 'package:shetravels/utils/helpers.dart';

Widget buildLogo(bool isMobile, Animation<double> scaleAnimation) {
  return ScaleTransition(
    scale: scaleAnimation,
    child: Container(
      margin: EdgeInsets.only(bottom: isMobile ? 32 : 48),
      child: Column(
        children: [
          Container(
            width: isMobile ? 120 : 140,
            height: isMobile ? 120 : 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.defaultWhiteColor.withOpacity(0.2),
                  AppColors.defaultWhiteColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.defaultWhiteColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: FutureBuilder(
              future: loadSvgAsset(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return SvgPicture.asset(
                    'assets/she_travel.svg',
                    semanticsLabel: 'SheTravels Logo',
                    colorFilter: const ColorFilter.mode(
                      AppColors.defaultWhiteColor,
                      BlendMode.srcIn,
                    ),
                  );
                } else {
                  return Icon(
                    Icons.travel_explore_rounded,
                    size: isMobile ? 60 : 70,
                    color: AppColors.defaultWhiteColor,
                  );
                }
              },
            ),
          ),

          SizedBox(height: isMobile ? 16 : 24),
          Text(
            "Join our community of empowered travelers",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppColors.defaultWhiteColor.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}
