import 'package:flutter/material.dart';

class TimelineStep {
  final String title;
  final String subtitle;
  final String? date;
  final IconData icon;
  final Color color;
  final bool completed;

  TimelineStep({
    required this.title,
    required this.subtitle,
    this.date,
    required this.icon,
    required this.color,
    required this.completed,
  });
}
