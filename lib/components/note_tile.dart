// note_tile.dart
import 'package:flutter/material.dart';
import 'package:notes/components/note_settings.dart';
import 'package:popover/popover.dart';

class NoteTile extends StatelessWidget {
  final String text;
  final void Function() onEditPressed;
  final void Function() onDeletePressed;

  const NoteTile({
    super.key,
    required this.text,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(8), // Add padding to increase internal spacing
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.5), // Adjust opacity to make it slightly transparent
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(
          top: 10, left: 20, right: 20), // Keep margin as it is
      child: ListTile(
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 20, // Adjust the font size as needed
          ),
        ),
        trailing: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.more_vert,
              size: 30, // Adjust size as needed
            ),
            onPressed: () => showPopover(
              width: 100,
              height: 100,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surface
                  .withOpacity(
                      0.9), // Slightly transparent background for the popover
              context: context,
              bodyBuilder: (context) => NoteSettings(
                onEditTap: onEditPressed,
                onDeleteTap: onDeletePressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
