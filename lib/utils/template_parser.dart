class TemplatePart {
  final String? text;
  final String? fieldKey;

  TemplatePart.text(this.text) : fieldKey = null;
  TemplatePart.field(this.fieldKey) : text = null;

  bool get isField => fieldKey != null;
}

List<TemplatePart> parseTemplate(String template) {
  // Match both {{ field }} and @{{ field }}
  final regex = RegExp(r'@?\{\{\s*(.*?)\s*\}\}');
  final matches = regex.allMatches(template);

  List<TemplatePart> parts = [];
  int lastIndex = 0;

  for (final match in matches) {
    if (match.start > lastIndex) {
      parts.add(TemplatePart.text(template.substring(lastIndex, match.start)));
    }
    parts.add(TemplatePart.field(match.group(1)!.trim()));
    lastIndex = match.end;
  }

  if (lastIndex < template.length) {
    parts.add(TemplatePart.text(template.substring(lastIndex)));
  }

  return parts;
}

