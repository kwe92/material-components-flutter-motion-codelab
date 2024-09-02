import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reply/home.dart';
import 'package:reply/search_page.dart';
import 'package:animations/animations.dart';

import 'model/router_provider.dart';

const String _homePageLocation = '/reply/home';
const String _searchPageLocation = '/reply/search';

class ReplyRouterDelegate extends RouterDelegate<ReplyRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReplyRoutePath> {
  ReplyRouterDelegate({required this.replyState}) : navigatorKey = GlobalObjectKey<NavigatorState>(replyState) {
    replyState.addListener(() {
      notifyListeners();
    });
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  RouterProvider replyState;

  @override
  void dispose() {
    replyState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  ReplyRoutePath get currentConfiguration => replyState.routePath;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouterProvider>.value(value: replyState),
      ],
      child: Selector<RouterProvider, ReplyRoutePath?>(
        selector: (context, routerProvider) => routerProvider.routePath,
        builder: (context, routePath, child) {
          return Navigator(
            key: navigatorKey,
            onPopPage: _handlePopPage,
            pages: [
              // TODO: Add Shared Z-Axis transition from search icon to search view page (Motion)

              const SharedAxisTransitionPageWrapper(
                transitionKey: ValueKey('Home'),
                screen: HomePage(),
              ),
              if (routePath is ReplySearchPath)
                // ?? replaced CustomTransitionPage with SharedAxisTransitionPageWrapper | understand why we need to wrap both HomePage and SearchPage with SharedAxisTransitionPageWrapper | to allow The home and search view screens should simultaneously fade and scale along the Z-axis in depth, creating a seamless effect between the two screens | why do both need their own ValueKey? | So the framework can differentiate between the two | How do we know when the framework needs to have a key?
                const SharedAxisTransitionPageWrapper(
                  transitionKey: ValueKey('Search'),
                  screen: SearchPage(),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    // _handlePopPage should not be called on the home page because the
    // PopNavigatorRouterDelegateMixin will bubble up the pop to the
    // SystemNavigator if there is only one route in the navigator.
    assert(route.willHandlePopInternally || replyState.routePath is ReplySearchPath);

    final bool didPop = route.didPop(result);
    if (didPop) replyState.routePath = const ReplyHomePath();
    return didPop;
  }

  @override
  Future<void> setNewRoutePath(ReplyRoutePath configuration) {
    replyState.routePath = configuration;
    return SynchronousFuture<void>(null);
  }
}

@immutable
abstract class ReplyRoutePath {
  const ReplyRoutePath();
}

class ReplyHomePath extends ReplyRoutePath {
  const ReplyHomePath();
}

class ReplySearchPath extends ReplyRoutePath {
  const ReplySearchPath();
}

// TODO: Add Shared Z-Axis transition from search icon to search view page (Motion)

class SharedAxisTransitionPageWrapper extends Page {
  final Widget screen;
  final ValueKey transitionKey;

  const SharedAxisTransitionPageWrapper({
    required this.screen,
    required this.transitionKey,
  }) : super(key: transitionKey);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionDuration: const Duration(seconds: 3),
      reverseTransitionDuration: const Duration(seconds: 3),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled, // SharedAxisTransitionType determines what axis the animation transitions on
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => screen,
    );
  }
}

class ReplyRouteInformationParser extends RouteInformationParser<ReplyRoutePath> {
  @override
  Future<ReplyRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final url = Uri.parse(routeInformation.location);

    if (url.path == _searchPageLocation) {
      return SynchronousFuture<ReplySearchPath>(const ReplySearchPath());
    }

    return SynchronousFuture<ReplyHomePath>(const ReplyHomePath());
  }

  @override
  RouteInformation? restoreRouteInformation(ReplyRoutePath configuration) {
    if (configuration is ReplyHomePath) {
      return const RouteInformation(location: _homePageLocation);
    }
    if (configuration is ReplySearchPath) {
      return const RouteInformation(location: _searchPageLocation);
    }
    return null;
  }
}

// SharedAxisTransition - Animated Widget - Shared Z-Axis Transition - animations package

//   - provides a transition between UI elements that have a spatial or navigational relationship

//   - outgoing and incoming elements share a fade transition without growing or shrinking

//   - when you want to fade in and out between two widgets that maybe their own views and you dont want a slide and fade transition but you want the transition to be on the z-axis (fade without sliding)

//!! - NOTE: SharedAxisTransition uses the themeData canvasColor for some transitions causing an unwanted
//!!          flash so the canvas color should match the scaffoldBackgroundColor to avoid flashing

//?? SharedAxisTransitionPageWrapper Implementation can be reused
