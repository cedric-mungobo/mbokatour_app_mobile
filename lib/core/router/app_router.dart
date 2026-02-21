import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/welcome/welcome_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/otp/otp_screen.dart';
import '../../presentation/screens/register/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/nearby/nearby_places_screen.dart';
import '../../presentation/screens/place_details/place_details_screen.dart';
import '../../presentation/screens/sections/section_details_screen.dart';
import '../../presentation/screens/sections/sections_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/contribute/contribute_screen.dart';
import '../../presentation/screens/preferences/preferences_screen.dart';

class AppRouter {
  static GoRoute _animatedRoute({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: builder(context, state),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  static GoRouter createRouter({required bool isLoggedIn}) {
    return GoRouter(
      initialLocation: isLoggedIn ? '/home' : '/',
      routes: [
        _animatedRoute(
          path: '/',
          builder: (context, state) => const WelcomeScreen(),
        ),
        _animatedRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        _animatedRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        _animatedRoute(
          path: '/otp',
          builder: (context, state) =>
              OtpScreen(initialEmail: state.uri.queryParameters['email']),
        ),
        _animatedRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        _animatedRoute(
          path: '/nearby',
          builder: (context, state) => const NearbyPlacesScreen(),
        ),
        _animatedRoute(
          path: '/sections',
          builder: (context, state) => const SectionsScreen(),
        ),
        _animatedRoute(
          path: '/sections/:slug',
          builder: (context, state) =>
              SectionDetailsScreen(slug: state.pathParameters['slug']!),
        ),
        _animatedRoute(
          path: '/place/:id',
          builder: (context, state) {
            final placeId = state.pathParameters['id']!;
            return PlaceDetailsScreen(placeId: placeId);
          },
        ),
        _animatedRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        _animatedRoute(
          path: '/contribute',
          builder: (context, state) => const ContributeScreen(),
        ),
        _animatedRoute(
          path: '/preferences',
          builder: (context, state) => const PreferencesScreen(),
        ),
      ],
    );
  }
}
