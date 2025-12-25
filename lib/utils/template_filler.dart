String fillTemplate(String template, Map<String, String> values) {
  // Replace @{{ key }} and {{ key }} with value from the map
  return template.replaceAllMapped(RegExp(r'@?\{\{\s*(.*?)\s*\}\}'), (match) {
    final key = match.group(1)?.trim();
    return values[key] ?? '';
  });
}
