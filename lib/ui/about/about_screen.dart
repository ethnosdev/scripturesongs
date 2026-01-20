import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 16);
    // Define the link style (primary color + underline)
    final linkStyle = baseStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.bold,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SelectableText(
              'Scripture Songs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final version = snapshot.data!.version;
                  return SelectableText('Version: $version', style: baseStyle);
                }
                // Placeholder while loading
                return SelectableText('Version: ...', style: baseStyle);
              },
            ),
            const SizedBox(height: 20),
            SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'The lyrics come from the '),
                  TextSpan(
                    text: 'Berean Standard Bible',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchBSBApp(context),
                  ),
                  const TextSpan(
                    text:
                        ' (a modern translation without copyright). The music was made with a paid account of Suno, which gives the song rights to the creator, who has then dedicated the songs to the public domain (CC0). Share or modify them as you like. No attribution required.',
                  ),
                ],
                style: baseStyle,
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              'So far this app only contains Philippians. Wouldn\'t it be great to have the whole Bible in music and without copyright? If you would like to help put more of the Bible to music and dedicate it to the public domain, please contact EthnosDev at contact@ethnos.dev.',
              style: baseStyle,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchBSBApp(BuildContext context) async {
    Uri url;

    if (Platform.isAndroid) {
      // Link to EthnosDev's BSB app on Google Play
      url = Uri.parse(
        'https://play.google.com/store/apps/details?id=dev.ethnos.bsb',
      );
    } else if (Platform.isIOS) {
      // Link to EthnosDev's BSB app on Apple App Store
      url = Uri.parse(
        'https://apps.apple.com/gb/app/berean-standard-bible/id6740620392',
      );
    } else {
      // Fallback for web/desktop to the website
      url = Uri.parse('https://berean.bible');
    }

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the app store link.')),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
