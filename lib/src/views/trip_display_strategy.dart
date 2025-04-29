import 'package:flutter/material.dart';

abstract class TripDisplayStrategy<T> {
  final List<T> data;
  final Function(T) onClick;
  TripDisplayStrategy(this.data, this.onClick);

  Widget buildWidget(BuildContext context);
}