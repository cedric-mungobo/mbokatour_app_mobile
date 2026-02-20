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
  static GoRouter createRouter({required bool isLoggedIn}) {
    return GoRouter(
      initialLocation: isLoggedIn ? '/home' : '/',
      routes: [
        // Welcome Screen
        GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),

        // Login Screen
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) =>
              OtpScreen(initialEmail: state.uri.queryParameters['email']),
        ),

        // Home Screen
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/nearby',
          builder: (context, state) => const NearbyPlacesScreen(),
        ),
        GoRoute(
          path: '/sections',
          builder: (context, state) => const SectionsScreen(),
        ),
        GoRoute(
          path: '/sections/:slug',
          builder: (context, state) =>
              SectionDetailsScreen(slug: state.pathParameters['slug']!),
        ),

        // Place Details Screen
        GoRoute(
          path: '/place/:id',
          builder: (context, state) {
            final placeId = state.pathParameters['id']!;
            return PlaceDetailsScreen(placeId: placeId);
          },
        ),

        // Profile Screen
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // Contribute Screen
        GoRoute(
          path: '/contribute',
          builder: (context, state) => const ContributeScreen(),
        ),
        GoRoute(
          path: '/preferences',
          builder: (context, state) => const PreferencesScreen(),
        ),
      ],
    );
  }
}
