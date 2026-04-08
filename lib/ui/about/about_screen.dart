import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isCopied = false;

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'contact@ethnos.dev'));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(fontSize: 16);
    final linkStyle = baseStyle?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scripture Songs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) => Text(
                'Version: ${snapshot.data?.version ?? '...'}',
                style: baseStyle,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "This is a project to put the words of the entire Bible to music. We believe that God's word should be available without cost and without restriction. All of the songs in this app are free to listen to, free to download, free to share, and free to modify.",
              style: baseStyle,
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "The lyrics are the plain text of the ",
                    style: baseStyle,
                  ),
                  TextSpan(
                    text: 'Berean Standard Bible',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchBSBApp(context),
                  ),
                  TextSpan(
                    text:
                        ", a modern English translation from Hebrew and Greek that was released to the public domain in 2023.",
                    style: baseStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "The music and voices were generated with Suno AI. Our goal is to create a select list of high quality songs that make it enjoyable to listen to scripture. We are not interested in mass producing AI slop.",
              style: baseStyle,
            ),
            const SizedBox(height: 16),
            Text(
              "If you would like to join this project and put one book or chapter of the Bible to music, please contact us.",
              style: baseStyle,
            ),
            const SizedBox(height: 40),
            Center(
              child: FilledButton.tonal(
                onPressed: _copyEmail,
                child: Text(_isCopied ? 'Copied!' : 'contact@ethnos.dev'),
              ),
            ),
            const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }

  Future<void> _launchBSBApp(BuildContext context) async {
    Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse(
        'https://play.google.com/store/apps/details?id=dev.ethnos.bsb',
      );
    } else if (Platform.isIOS) {
      url = Uri.parse(
        'https://apps.apple.com/gb/app/berean-standard-bible/id6740620392',
      );
    } else {
      url = Uri.parse('https://berean.bible');
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the app store link.')),
        );
      }
    }
  }
}
