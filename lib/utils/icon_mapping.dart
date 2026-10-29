import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'monument':
      return Icons.castle;
    case 'nature':
      return Icons.park;
    case 'restaurant':
      return Icons.restaurant;
    case 'musée':
      return Icons.museum;
    case 'café':
      return Icons.local_cafe;
    case 'bar':
      return Icons.local_bar;
    case 'hôtel':
    case 'hotel':
      return Icons.hotel;
    case 'shopping':
      return Icons.shopping_cart;
    case 'transport':
      return Icons.train;
    default:
      return Icons.place;
  }
}
