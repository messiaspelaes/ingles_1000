/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 */

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'license_info.dart';

/// Tela "Sobre" com informações de licenciamento e créditos
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informações do App
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LicenseInfo.appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versão ${LicenseInfo.version}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplicativo de repetição espaçada baseado no método Anki, '
                    'utilizando o algoritmo FSRS para otimização do aprendizado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Licenças de Terceiros
          Text(
            'Licenças de Terceiros',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...LicenseInfo.thirdPartyLicenses.map((license) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              license.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(license.license),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(license.description),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchURL(license.url),
                        child: Text(
                          license.url,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 24),

          // Licença GPL v3
          Text(
            'Licença',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                LicenseInfo.gplv3Text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Créditos
          Text(
            'Créditos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Este aplicativo utiliza código adaptado do AnkiDroid, '
                    'um projeto open source licenciado sob GPL v3.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AnkiDroid é desenvolvido pela comunidade AnkiDroid e '
                    'contribuidores. Para mais informações, visite:',
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchURL(
                        'https://github.com/ankidroid/Anki-Android'),
                    child: Text(
                      'https://github.com/ankidroid/Anki-Android',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

