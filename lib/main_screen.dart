import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_note_screen.dart';
import 'edit_note_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'providers/providers.dart';
import 'models/note_model.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _log = Logger('MainScreenState');
  int _selectedIndex = 0;
  bool _isNavBarVisible = true;

  static const Duration _kTransitionDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _log.fine("initState called");
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _log.fine("Navigation item tapped: index $index");
      FocusScope.of(context).unfocus();
      setState(() {
        _selectedIndex = index;
      });

      // Fix for search bar getting focused on settings screen after exiting update check screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
          _log.fine("Requested focus on a new empty node after tab switch frame.");
        }
      });
    }
  }

  void _navigateToAddNote() async {
    _log.info("Navigating to Add Note screen");
    FocusScope.of(context).unfocus();

    if(mounted) {
      setState(() => _isNavBarVisible = false);
    }

    await Navigator.push<void>(
      context,
      // PageRouteBuilder doesn't seem to work with predictive back gesture yet, replace with this if needed
      // MaterialPageRoute(builder: (context) => const AddNoteScreen()),
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddNoteScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const Offset begin = Offset(1.0, 0.0);
          const Offset end = Offset.zero;
          const Curve curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: _kTransitionDuration,
      ),
    );

    if(mounted) {
      setState(() => _isNavBarVisible = true);
    }
  }

  Future<void> _navigateToEditNote(Note noteToEdit) async {
    _log.info("Navigating to Edit Note screen for ID: ${noteToEdit.id}");
    FocusScope.of(context).unfocus();

    if(mounted) {
      setState(() => _isNavBarVisible = false);
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          noteId: noteToEdit.id,
          heroTag: noteToEdit.heroTag,
        ),
      ),
    );

    if(mounted) {
      setState(() => _isNavBarVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _log.finer("Building MainScreen widget");
    final navBarOffset = _isNavBarVisible ? Offset.zero : const Offset(0.0, 1.1);
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resize on keyboard
      body: notesAsync.when(
        data: (notes) {
          _log.finer("Notes data received: ${notes.length} notes.");
          final List<Widget> widgetOptions = <Widget>[
            HomeScreen(
              notes: notes,
              onNoteTap: _navigateToEditNote,
            ),
            const SettingsScreen(),
          ];
          return IndexedStack(
            index: _selectedIndex,
            children: widgetOptions,
          );
        },
        loading: () {
           _log.finer("Displaying loading indicator.");
           return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          _log.severe("Error loading notes", error, stackTrace);
          return Center(
            child: Text(
              'Error loading notes:\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        },
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddNote,
              tooltip: 'Add Note',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: AnimatedSlide(
        duration: _kTransitionDuration,
        offset: navBarOffset,
        curve: Curves.easeInOut, // Match page transition curve
        child: NavigationBar(
          destinations: const <NavigationDestination>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.settings),
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          // Prevent animation causing issues if nav bar rebuilds mid-animation
          // key: ValueKey(_selectedIndex),
        ),
      ),
    );
  }
}