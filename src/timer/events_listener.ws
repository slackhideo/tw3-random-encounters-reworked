
abstract class RER_EventsListener {
  public var active: bool;

  public latent function onReady(manager: RER_EventsManager) {
    this.active = true;
  }

  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float): bool {
    // Do your thing and return if a spawn was triggered or not

    return was_spawn_already_triggered;
  }
}