import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class JsonLdPreviewPane extends StatelessWidget {
  const JsonLdPreviewPane({
    super.key,
    required this.code,
  });

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = code.split('\n');

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.code, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  'Live JSON-LD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Synthesized',
                    style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: theme.scaffoldBackgroundColor.withOpacity(0.5),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy JSON-LD',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('JSON-LD copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  tooltip: 'Validate on Schema.org',
                  onPressed: () async {
                    final uri = Uri.parse('https://validator.schema.org/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  tooltip: 'Google Rich Results Test',
                  onPressed: () async {
                    final uri = Uri.parse('https://search.google.com/test/rich-results');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                const Spacer(),
                Text(
                  '${lines.length} lines',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Code View with Line Numbers
          Expanded(
            child: Container(
              color: const Color(0xFF0D1117), // GitHub / IDE Dark Code Background
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 500,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${index + 1}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Consolas, monospace',
                                fontSize: 12,
                                color: Color(0xFF484F58),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildSyntaxHighlightedLine(line),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxHighlightedLine(String line) {
    final spans = <TextSpan>[];
    final trimmed = line.trimLeft();
    final leadingSpaces = line.length - trimmed.length;
    final indent = ' ' * leadingSpaces;

    if (trimmed.startsWith('"@context"') ||
        trimmed.startsWith('"@type"') ||
        trimmed.startsWith('"@id"') ||
        trimmed.startsWith('"@base"') ||
        trimmed.startsWith('"@vocab"')) {
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx != -1) {
        final keyPart = trimmed.substring(0, colonIdx);
        final rest = trimmed.substring(colonIdx);
        spans.add(TextSpan(text: indent));
        spans.add(TextSpan(
          text: keyPart,
          style: const TextStyle(color: Color(0xFFFF7B72), fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(
          text: rest,
          style: const TextStyle(color: Color(0xFFA5D6FF)),
        ));
      } else {
        spans.add(TextSpan(text: line, style: const TextStyle(color: Color(0xFFFF7B72))));
      }
    } else if (trimmed.startsWith('"') && trimmed.contains('":')) {
      final colonIdx = trimmed.indexOf('":');
      final keyPart = trimmed.substring(0, colonIdx + 1);
      final rest = trimmed.substring(colonIdx + 1);

      spans.add(TextSpan(text: indent));
      spans.add(TextSpan(
        text: keyPart,
        style: const TextStyle(color: Color(0xFF79C0FF)), // Property Key Cyan/Blue
      ));
      spans.add(TextSpan(
        text: rest,
        style: const TextStyle(color: Color(0xFFA5D6FF)), // Value string Light Blue
      ));
    } else {
      spans.add(TextSpan(
        text: line,
        style: const TextStyle(color: Color(0xFFC9D1D9)),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(
          fontFamily: 'Consolas, monospace',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
