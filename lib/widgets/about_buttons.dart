import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/standard_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

// This file contains a privacy policy button widget and an about button widget
class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardSettingsButton("Privacy policy", Icon(Icons.privacy_tip), () async {
      final url = Uri.parse("https://github.com/MarcoBonato2007/QuoteLike/blob/main/PRIVACY_POLICY.md");
      if (!await launchUrl(url) && context.mounted) {
        showToast(
          context, 
          "test",
          Duration(seconds: 3)
        );
      }
    });
  }
}

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardSettingsButton("About", Icon(Icons.info), () async {
      if (context.mounted) {
        showAboutDialog(
          context: context,
          applicationName: "QuoteLike",
          applicationIcon: Icon(Icons.format_quote),
          children: [Text("QuoteLike is an app where you can scroll a collection of quotes, and find those you like.")],
          applicationVersion: (await PackageInfo.fromPlatform()).version,
        );            
      }
    });
  }
}
