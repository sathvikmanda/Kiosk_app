import 'package:flutter/material.dart';

class InactivityWrapper extends StatelessWidget {
  const InactivityWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}