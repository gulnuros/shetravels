import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:shetravels/utils/route.gr.dart';
import 'package:shetravels/utils/string.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter();
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: SplashRoute.page,
      initial: true,
      path: RouteString.splashScreen,
    ),
//
  AutoRoute(page: LoginRoute.page, path: RouteString.login),
    AutoRoute(page: SignupRoute.page, path: RouteString.signup),
     AutoRoute(page: ForgetPasswordRoute.page, path: RouteString.forgetPassword),
    //
    AutoRoute(page: HomeRoute.page, path: RouteString.homeScreen),
    AutoRoute(page: AdminGalleryRoute.page, path: RouteString.adminGallery),
    AutoRoute(page: AdminMemoriesRoute.page, path: RouteString.adminMemories),
    AutoRoute(page: AdminLoginRoute.page, path: RouteString.adminLogin),
    AutoRoute(page: AdminPanelRoute.page, path: RouteString.adminPanel),
 AutoRoute(page: AdminDashboardRoute.page, path: RouteString.adminDashboard),
  AutoRoute(page: AdminManageEventRoute.page, path: RouteString.manageEvent),
    AutoRoute(page: AdminBookingDashboardRoute.page, path: RouteString.adminBookingDashboard),
 
        AutoRoute(page: AddTestimonialRoute.page, path: RouteString.adminTestimonial),
      AutoRoute(page: PaymentSuccessRoute.page, path: RouteString.success),
 
      AutoRoute(page: PaymentCancelRoute.page, path: RouteString.cancel),

  ];
}
