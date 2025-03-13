import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';

class EpgProgram {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? category;
  final String? iconUrl;

  EpgProgram({
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.category,
    this.iconUrl,
  });

  Duration get duration => end.difference(start);
  bool get isCurrentlyOn =>
      DateTime.now().isAfter(start) && DateTime.now().isBefore(end);

  String get formattedStartTime => DateFormat('HH:mm').format(start);
  String get formattedEndTime => DateFormat('HH:mm').format(end);
}

class EpgChannel {
  final String id;
  final String name;
  final String? logoUrl;
  final List<EpgProgram> programs;

  EpgChannel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.programs,
  });

  EpgProgram? get currentProgram => programs.firstWhere(
    (program) => program.isCurrentlyOn,
    orElse: () => programs.isEmpty ? null : programs.first,
  );

  List<EpgProgram> get upcomingPrograms {
    final now = DateTime.now();
    return programs.where((program) => program.start.isAfter(now)).toList();
  }
}

class EpgService {
  static final EpgService _instance = EpgService._internal();
  factory EpgService() => _instance;
  EpgService._internal();

  final Map<String, EpgChannel> _channels = {};
  DateTime? _lastFetch;

  Map<String, EpgChannel> get channels => _channels;
  bool get hasData => _channels.isNotEmpty;

  Future<void> fetchEpgData(String epgUrl) async {
    try {
      // Check if we need to refresh (every 4 hours)
      final now = DateTime.now();
      if (_lastFetch != null &&
          now.difference(_lastFetch!).inHours < 4 &&
          _channels.isNotEmpty) {
        return;
      }

      final response = await http.get(Uri.parse(epgUrl));

      if (response.statusCode == 200) {
        final data = response.body;

        // XMLTV format parsing
        if (epgUrl.toLowerCase().endsWith('.xml') ||
            epgUrl.toLowerCase().contains('xmltv')) {
          await _parseXmltvData(data);
        }
        // Add other format parsing here if needed

        _lastFetch = now;
      } else {
        throw Exception('Failed to load EPG data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching EPG data: $e');
      rethrow;
    }
  }

  Future<void> _parseXmltvData(String xmlData) async {
    try {
      final document = XmlDocument.parse(xmlData);
      final channelElements = document.findAllElements('channel');
      final programmeElements = document.findAllElements('programme');

      _channels.clear();

      // Parse channels
      for (var channelElement in channelElements) {
        final id = channelElement.getAttribute('id') ?? '';
        final names = channelElement.findAllElements('display-name');
        final icons = channelElement.findAllElements('icon');

        final name = names.isNotEmpty ? names.first.innerText : id;
        final logoUrl =
            icons.isNotEmpty ? icons.first.getAttribute('src') : null;

        _channels[id] = EpgChannel(
          id: id,
          name: name,
          logoUrl: logoUrl,
          programs: [],
        );
      }

      // Parse programs
      for (var programElement in programmeElements) {
        final channelId = programElement.getAttribute('channel') ?? '';
        if (!_channels.containsKey(channelId)) continue;

        final startStr = programElement.getAttribute('start') ?? '';
        final endStr = programElement.getAttribute('stop') ?? '';
        final title =
            programElement.findElements('title').firstOrNull?.innerText ??
            'Unknown';
        final desc = programElement.findElements('desc').firstOrNull?.innerText;
        final category =
            programElement.findElements('category').firstOrNull?.innerText;
        final iconElement = programElement.findElements('icon').firstOrNull;
        final iconUrl = iconElement?.getAttribute('src');

        // Parse XMLTV date format (20240615123000 +0000)
        DateTime? start, end;
        try {
          if (startStr.isNotEmpty) {
            start = _parseXmltvDateTime(startStr);
          }
          if (endStr.isNotEmpty) {
            end = _parseXmltvDateTime(endStr);
          }
        } catch (e) {
          debugPrint('Error parsing program dates: $e');
          continue;
        }

        if (start != null && end != null) {
          _channels[channelId]!.programs.add(
            EpgProgram(
              title: title,
              description: desc,
              start: start,
              end: end,
              category: category,
              iconUrl: iconUrl,
            ),
          );
        }
      }

      // Sort programs by start time
      for (var channel in _channels.values) {
        channel.programs.sort((a, b) => a.start.compareTo(b.start));
      }
    } catch (e) {
      debugPrint('Error parsing XMLTV data: $e');
      rethrow;
    }
  }

  // Helper to parse XMLTV date format: 20240615123000 +0000
  DateTime _parseXmltvDateTime(String dateStr) {
    // Remove space and timezone for simplicity
    final cleanDateStr = dateStr.split(' ').first;
    if (cleanDateStr.length < 14)
      throw const FormatException('Invalid date format');

    final year = int.parse(cleanDateStr.substring(0, 4));
    final month = int.parse(cleanDateStr.substring(4, 6));
    final day = int.parse(cleanDateStr.substring(6, 8));
    final hour = int.parse(cleanDateStr.substring(8, 10));
    final minute = int.parse(cleanDateStr.substring(10, 12));
    final second = int.parse(cleanDateStr.substring(12, 14));

    return DateTime(year, month, day, hour, minute, second);
  }

  // Find program information for a specific channel by matching name
  EpgChannel? findChannelByName(String channelName) {
    final normalized = channelName.toLowerCase().trim();

    return _channels.values.firstWhere(
      (channel) => channel.name.toLowerCase().contains(normalized),
      orElse:
          () => _channels.values.firstWhere(
            (channel) => normalized.contains(channel.name.toLowerCase()),
            orElse: () => null,
          ),
    );
  }
}
