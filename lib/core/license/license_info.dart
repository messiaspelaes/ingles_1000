/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Adaptado de AnkiDroid (GPL v3) - https://github.com/ankidroid/Anki-Android
 */

/// Informações de licenciamento e créditos do aplicativo
class LicenseInfo {
  static const String appName = 'Inglês 1000';
  static const String version = '1.0.0';
  static const String license = 'GPL v3';

  /// Licenças de terceiros utilizadas no projeto
  static const List<ThirdPartyLicense> thirdPartyLicenses = [
    ThirdPartyLicense(
      name: 'AnkiDroid',
      license: 'GPL v3',
      url: 'https://github.com/ankidroid/Anki-Android',
      description:
          'Algoritmo FSRS e estrutura de dados de cards adaptados do AnkiDroid',
    ),
    ThirdPartyLicense(
      name: 'FSRS (Free Spaced Repetition Scheduler)',
      license: 'MIT',
      url: 'https://github.com/open-spaced-repetition/fsrs4anki',
      description: 'Algoritmo de repetição espaçada otimizado por IA',
    ),
  ];

  /// Texto completo da licença GPL v3 (resumido)
  static const String gplv3Text = '''
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
''';
}

/// Informações sobre licenças de terceiros
class ThirdPartyLicense {
  final String name;
  final String license;
  final String url;
  final String description;

  const ThirdPartyLicense({
    required this.name,
    required this.license,
    required this.url,
    required this.description,
  });
}

