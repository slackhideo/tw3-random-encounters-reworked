state Spawning in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    parent.RemoveTimer('randomEncounterTick');

    super.OnEnterState(previous_state_name);
    LogChannel('modRandomEncounters', "Entering state SPAWNING");

    triggerCreaturesSpawn();
  }

  entry function triggerCreaturesSpawn() {
    var picked_entity_type: EEncounterType;

    LogChannel('modRandomEncounters', "creatures spawning triggered");
    
    if (this.shouldAbortCreatureSpawn()) {
      parent.GotoState('SpawningCancelled');

      return;
    }

    picked_entity_type = this.getRandomEntityTypeWithSettings();

    LogChannel('modRandomEncounters', "picked entity type: " + picked_entity_type);

    // this.trySpawnHuman();

    makeGroupComposition(ET_HUMAN, parent);

    switch (picked_entity_type) {
      case ET_GROUND:
        LogChannel('modRandomEncounters', "spawning type ET_GROUND ");
        break;

      case ET_FLYING:
        LogChannel('modRandomEncounters', "spawning type ET_FLYING ");
        break;

      case ET_HUMAN:
        LogChannel('modRandomEncounters', "spawning type ET_HUMAN ");
        break;

      case ET_GROUP:
        LogChannel('modRandomEncounters', "spawning type ET_GROUP ");
        break;

      case ET_WILDHUNT:
        LogChannel('modRandomEncounters', "spawning type ET_WILDHUNT ");
        break;

      case ET_NONE:
        // do nothing when no EntityType was available
        // this is here for reminding me this case exists.
        break;
    }
  }

  function shouldAbortCreatureSpawn(): bool {
    var current_state: CName;
    var is_meditating: bool;
    var current_zone: EREZone;


    current_state = thePlayer.GetCurrentStateName();
    is_meditating = current_state == 'Meditation' && current_state == 'MeditationWaiting';
    current_zone = parent.rExtra.getCustomZone(thePlayer.GetWorldPosition());

    return is_meditating 
        || thePlayer.IsInInterior()
        || thePlayer.IsInCombat()
        || thePlayer.IsUsingBoat()
        || thePlayer.IsInFistFightMiniGame()
        || thePlayer.IsSwimming()
        || thePlayer.IsInNonGameplayCutscene()
        || thePlayer.IsInGameplayScene()
        || theGame.IsDialogOrCutscenePlaying()
        || theGame.IsCurrentlyPlayingNonGameplayScene()
        || theGame.IsFading()
        || theGame.IsBlackscreen()
        || current_zone == REZ_CITY 
        && !parent.settings.cityBruxa 
        && !parent.settings.citySpawn;
  }

  latent function trySpawnHuman() {
    var number_of_humans: int;
    var picked_human_type: EHumanType;
    var initial_human_position: Vector;
    var template_human_array: array<SEnemyTemplate>;

    LogChannel('modRandomEncounters', "trying to spawn humans");

    if (!this.getInitialHumanPosition(initial_human_position, 15)) {
        LogChannel('modRandomEncounters', "could not get initial human position");

      // could net get a proper initial position
      return;
    }

    LogChannel('modRandomEncounters', "could get initial human position");

    picked_human_type = parent.rExtra.getRandomHumanTypeByCurrentArea();
    
    template_human_array = parent.resources.copy_template_list(
      parent.resources.getHumanResourcesByHumanType(picked_human_type)
    );

    number_of_humans = RandRange(
      4 + parent.settings.selectedDifficulty,
      6 + parent.settings.selectedDifficulty
    );

    this.spawnGroupOfEntities(template_human_array, number_of_humans, initial_human_position);

    parent.GotoState('Waiting');
  }

  latent function trySpawnGroundCreatures() {
    var entity_template: CEntityTemplate;
    var number_of_creatures: int;
    var picked_creature_type: EGroundMonsterType;

    LogChannel('modRandomEncounters', "trying to spawn ground creatures");

  }

  private function getInitialHumanPosition(out initial_pos: Vector, optional distance: float) : bool {
    var collision_normal: Vector;
    var camera_direction: Vector;
    var player_position: Vector;

    camera_direction = theCamera.GetCameraDirection();

    if (distance == 0.0) {
      distance = 3.0; // meters
    }

    camera_direction.X *= -distance;
    camera_direction.Y *= -distance;

    player_position = thePlayer.GetWorldPosition();

    initial_pos = player_position + camera_direction;
    initial_pos.Z = player_position.Z;

    return theGame
      .GetWorld()
      .StaticTrace(
        initial_pos + 5,// Vector(0,0,5),
        initial_pos - 5,//Vector(0,0,5),
        initial_pos,
        collision_normal
      );
  }

  latent function spawnGroupOfEntities(entities_templates: array<SEnemyTemplate>, total_number_of_entities: int, initial_entity_position: Vector) {
    var current_entity_template: SEnemyTemplate;
    var current_entity_position: Vector;
    var selected_template_to_increment: int;
    var i: int;

    LogChannel('modRandomEncounters', "spawning total of " + total_number_of_entities + " entities");

    // randomly increase the entity count for each type of template
    // based on the maximum of entities this entity template allows
    while (total_number_of_entities > 0) {
      selected_template_to_increment = RandRange(entities_templates.Size());

      LogChannel('modRandomEncounters', "selected template: " + selected_template_to_increment);

      if (entities_templates[selected_template_to_increment].max > -1
       && entities_templates[selected_template_to_increment].count >= entities_templates[selected_template_to_increment].max) {
        continue;
      }

      entities_templates[selected_template_to_increment].count += 1;

      total_number_of_entities -= 1;
    }

    for (i = 0; i < entities_templates.Size(); i += 1) {
      current_entity_template = entities_templates[i];

      if (current_entity_template.count > 0) {
        this.spawnEntities(
          (CEntityTemplate)LoadResource(current_entity_template.template, true),
          initial_entity_position,
          current_entity_template.count
        );
      }
    }
  }

  latent function spawnEntities(entity_template: CEntityTemplate, initial_position: Vector, optional quantity: int) {
    var ent: CEntity;
    var player, pos_fin, normal: Vector;
    var rot: EulerAngles;
    var i, sign: int;
    var s, r, x, y: float;
    var createEntityHelper: CCreateEntityHelper;
    
    quantity = Max(quantity, 1);

    LogChannel('modRandomEncounters', "spawning " + quantity + " entities");
  
    rot = thePlayer.GetWorldRotation();  

    //const values used in the loop
    pos_fin.Z = initial_position.Z;
    s = quantity / 0.2; // maintain a constant density of 0.2 unit per m2
    r = SqrtF(s/Pi());

    createEntityHelper = new CCreateEntityHelper in this;
    createEntityHelper.SetPostAttachedCallback(this, 'onEntitySpawned');

    for (i = 0; i < quantity; i += 1) {
      x = RandF() * r;        // add random value within range to X
      y = RandF() * (r - x);  // add random value to Y so that the point is within the disk

      if(RandRange(2))        // randomly select the sign for misplacement
        sign = 1;
      else
        sign = -1;
        
      pos_fin.X = initial_position.X + sign * x;  //final X pos
      
      if(RandRange(2))        // randomly select the sign for misplacement
        sign = 1;
      else
        sign = -1;
        
      pos_fin.Y = initial_position.Y + sign * y;  //final Y pos

      theGame.GetWorld().StaticTrace( pos_fin + Vector(0,0,3), pos_fin - Vector(0,0,3), pos_fin, normal);

      createEntityHelper.Reset();
      theGame.CreateEntityAsync(createEntityHelper, entity_template, pos_fin, rot, true, false, false, PM_DontPersist);

      LogChannel('modRandomEncounters', "spawning entity at " + pos_fin.X + " " + pos_fin.Y + " " + pos_fin.Z);

      while(createEntityHelper.IsCreating()) {            
        SleepOneFrame();
      }
      
      // l_splitEntity = m_createEntityHelper.GetCreatedEntity();
    }
  }

  function onEntitySpawned(entity: CEntity) {
    var summon: CNewNPC;
    LogChannel('modRandomEncounters', "1 entity spawned");
    

    summon = ( CNewNPC ) entity;

    summon.SetLevel(GetWitcherPlayer().GetLevel());
    summon.NoticeActor(thePlayer);
    summon.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
  }

  function getRandomEntityTypeWithSettings(): EEncounterType {
    var choice : array<EEncounterType>;

    if (theGame.envMgr.IsNight()) {
      choice = this.getRandomEntityTypeForNight();
    }
    else {
      choice = this.getRandomEntityTypeForDay();
    }

    if (choice.Size() < 1) {
      return ET_NONE;
    }

    return choice[RandRange(choice.Size())];
  }

  function getRandomEntityTypeForNight(): array<EEncounterType> {
    var choice: array<EEncounterType>;
    var i: int;

    for (i = 0; i < parent.settings.isGroundActiveN; i += 1) {
      choice.PushBack(ET_GROUND);
    }

    // TODO: add inForest factor, maybe 0.5?
    for (i = 0; i < parent.settings.isFlyingActiveN; i += 1) {
      choice.PushBack(ET_FLYING);
    }

    for (i = 0; i < parent.settings.isHumanActiveN; i += 1) {
      choice.PushBack(ET_HUMAN);
    }

    for (i = 0; i < parent.settings.isGroupActiveN; i += 1) {
      choice.PushBack(ET_GROUP);
    }

    for (i = 0; i < parent.settings.isWildHuntActiveN; i += 1) {
      choice.PushBack(ET_WILDHUNT);
    }

    return choice;
  }

  function getRandomEntityTypeForDay(): array<EEncounterType> {
    var choice: array<EEncounterType>;
    var i: int;

    for (i = 0; i < parent.settings.isGroundActiveD; i += 1) {
      choice.PushBack(ET_GROUND);
    }

    // TODO: add inForest factor, maybe 0.5?
    for (i = 0; i < parent.settings.isFlyingActiveD; i += 1) {
      choice.PushBack(ET_FLYING);
    }

    for (i = 0; i < parent.settings.isHumanActiveD; i += 1) {
      choice.PushBack(ET_HUMAN);
    }

    for (i = 0; i < parent.settings.isGroupActiveD; i += 1) {
      choice.PushBack(ET_GROUP);
    }

    for (i = 0; i < parent.settings.isWildHuntActiveD; i += 1) {
      choice.PushBack(ET_WILDHUNT);
    }

    return choice;
  }
}