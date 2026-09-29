import 'package:flutter/material.dart';

class BottlePreset {
  final String id;
  final String name;
  final int amount;
  final IconData icon;
  final bool isCustom;

  const BottlePreset({
    required this.id,
    required this.name,
    required this.amount,
    required this.icon,
    this.isCustom = false,
  });

  static List<BottlePreset> defaults = [
    const BottlePreset(
      id: 'shot',
      name: 'Shot',
      amount: 50,
      icon: Icons.local_bar_outlined,
    ),
    const BottlePreset(
      id: 'small_glass',
      name: 'Small Glass',
      amount: 150,
      icon: Icons.local_drink_outlined,
    ),
    const BottlePreset(
      id: 'glass',
      name: 'Glass',
      amount: 250,
      icon: Icons.water_drop_outlined,
    ),
    const BottlePreset(
      id: 'large_glass',
      name: 'Large Glass',
      amount: 350,
      icon: Icons.local_cafe_outlined,
    ),
    const BottlePreset(
      id: 'small_bottle',
      name: 'Small Bottle',
      amount: 500,
      icon: Icons.liquor_outlined,
    ),
    const BottlePreset(
      id: 'bottle',
      name: 'Bottle',
      amount: 750,
      icon: Icons.water_outlined,
    ),
    const BottlePreset(
      id: 'large_bottle',
      name: 'Large Bottle',
      amount: 1000,
      icon: Icons.water_outlined,
    ),
  ];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'isCustom': isCustom,
  };

  factory BottlePreset.fromMap(Map<String, dynamic> map) => BottlePreset(
    id: map['id'] as String,
    name: map['name'] as String,
    amount: map['amount'] as int,
    icon: Icons.local_drink_outlined,
    isCustom: map['isCustom'] as bool? ?? true,
  );
}
