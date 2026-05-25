class AlteriOneCore {
  final EventBus eventBus;
  final AgentConfig config;
  final ModuleRegistry moduleRegistry;
  final PersonaManager personaManager;
  final ConversationManager conversationManager;
  final MemoryRouter memoryRouter;
  final LlmRouter llmRouter;
  final SkillDispatcher skillDispatcher;
  final ApiServer apiServer;

  // Фабричный конструктор — читает конфиг и собирает граф зависимостей
  static Future<AlteriOneCore> create(String configPath) async {
    final config = await ConfigLoader.load(configPath);
    final eventBus = EventBus();
    final registry = ModuleRegistry(eventBus);
    // ...
    return AlteriOneCore._internal(...);
  }

  Future<void> start() async {
    await Bootstrap.run(this);   // строгий порядок запуска
    await apiServer.serve();
  }

  Future<void> shutdown() async {
    await apiServer.close();
    await moduleRegistry.disposeAll();
    eventBus.dispose();
  }
}
