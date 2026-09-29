import 'package:flutter/material.dart';
import 'package:smart_water_reminder/core/utils/date_utils.dart' as date_utils;
import 'package:smart_water_reminder/data/models/water_intake.dart';

class IntakeTile extends StatefulWidget {
  final WaterIntake intake;
  final bool isLast;
  final Color sectionColor;
  final VoidCallback onDelete;

  const IntakeTile({
    super.key,
    required this.intake,
    required this.isLast,
    required this.sectionColor,
    required this.onDelete,
  });

  @override
  State<IntakeTile> createState() => _IntakeTileState();
}

class _IntakeTileState extends State<IntakeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = date_utils.AppDateUtils.formatTime(widget.intake.timestamp);
    final amount = widget.intake.amount;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child!,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: _buildContent(context, time, amount),
            ),
            _buildDeleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: widget.sectionColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.sectionColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        if (!widget.isLast)
          Expanded(
            child: Container(
              width: 2,
              color: widget.sectionColor.withValues(alpha: 0.3),
              margin: const EdgeInsets.only(top: 4),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, String time, int amount) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.sectionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_drink_outlined,
              color: widget.sectionColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$amount ml',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: widget.onDelete,
      icon: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.error,
        size: 22,
      ),
      tooltip: 'Delete',
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.errorContainer,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}