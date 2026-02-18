import 'package:go_router/go_router.dart';
import '../../presentation/screens/welcome/welcome_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/place_details/place_details_screen.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Welcome Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      
      // Login Screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Home Screen
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Place Details Screen
      GoRoute(
        path: '/place/:id',
        builder: (context, state) {
          final placeId = state.pathParameters['id']!;
          return PlaceDetailsScreen(placeId: placeId);
        },
      ),
    ],
  );
}

