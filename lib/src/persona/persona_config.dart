class PersonaConfig {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final LlmPersonaConfig llm;
  final MemoryPersonaConfig memory;
  final List<String> skillIds;
  final PersonaStyle style;

  // Содержимое текстовых файлов
  final String systemPrompt;
  final String rules;
  final String styleGuide;
  final List<KnowledgeEntry> knowledge;
  final List<ExampleEntry> examples;
}
