/*
 * Copyright (c) 2025
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 */

/// Utilitários para manipulação de datas
class DateUtils {
  /// Converte timestamp do Anki (dias desde epoch) para DateTime
  static DateTime ankiTimestampToDateTime(int timestamp) {
    // Anki usa dias desde epoch (1970-01-01) para due dates
    // Se o timestamp é menor que um valor grande, assume-se que são dias
    if (timestamp < 1000000000) {
      // É um timestamp em dias
      final epoch = DateTime(1970, 1, 1);
      return epoch.add(Duration(days: timestamp));
    } else {
      // É um timestamp em milissegundos
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  /// Converte DateTime para timestamp do Anki (dias desde epoch)
  static int dateTimeToAnkiTimestamp(DateTime dateTime) {
    final epoch = DateTime(1970, 1, 1);
    return dateTime.difference(epoch).inDays;
  }
}

