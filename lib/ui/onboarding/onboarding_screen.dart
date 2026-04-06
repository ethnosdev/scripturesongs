import 'package:flutter/material.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:scripturesongs/ui/home/home_screen.dart';

class OnboardingData {
  final String text;
  final IconData icon;

  OnboardingData({required this.text, required this.icon});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      text: "This is a project to put the words of the entire Bible to music.",
      icon: Icons.music_note_rounded,
    ),
    OnboardingData(
      text:
          "We believe that God's word should be available without cost and without restriction.",
      icon: Icons.volunteer_activism_rounded,
    ),
    OnboardingData(
      text:
          "All of the songs in this app are free to listen to, free to download, free to share, and free to modify.",
      icon: Icons.share_rounded,
    ),
    OnboardingData(
      text:
          "The lyrics are the plain text of the Berean Standard Bible, a modern English translation from Hebrew and Greek that was released to the public domain in 2023.",
      icon: Icons.menu_book_rounded,
    ),
    OnboardingData(
      text:
          "The music and voices were generated with Suno AI. Our goal is to create a select list of high quality songs that make it enjoyable to listen to scripture. We are not interested in mass producing AI slop.",
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingData(
      text:
          "If you would like to join this project and put one book or chapter of the Bible to music, please contact us.",
      icon: Icons.group_add_rounded,
    ),
  ];

  Future<void> _finishOnboarding() async {
    final userSettings = getIt<UserSettings>();
    await userSettings.setHasSeenOnboarding(true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button at Top
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text('Skip'),
              ),
            ),

            // Carousel Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _pages[index].icon,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index].text,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Nav Area (Dots + Next Button)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8.0),
                        height: 8.0,
                        width: _currentPage == index ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),

                  // Next / Done Button
                  FilledButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Done' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
