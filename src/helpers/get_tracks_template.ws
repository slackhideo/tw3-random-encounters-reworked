
latent function getTracksTemplate(actor : CActor): CEntityTemplate {
  var monsterCategory : EMonsterCategory
  var soundMonsterName : CName;
  var isTeleporting : bool;
  var canBeTargeted : bool;
  var canBeHitByFists : bool;

  theGame.GetMonsterParamsForActor(
    actor,
    monsterCategory,
    soundMonsterName,
    isTeleporting,
    canBeTargeted,canBeTargeted
  );

  switch(mc) {
    case MC_Specter :
    case MC_Magicals :
      // TODO: find specter tracks
      return (CEntityTemplate)LoadResourceAsync(
        "quests\generic_quests\no_mans_land\quest_files\mh108_fogling\entities\mh108_clue_fogling_tracks.w2ent",
        true
      );
      break;
        
      break;
        
    case MC_Vampire :
    case MC_Human :
      // TODO: find human tracks
      return (CEntityTemplate)LoadResourceAsync(
        "quests\generic_quests\skellige\quest_files\mh202_nekker_warrior\entities\mh202_nekker_tracks.w2ent",
        true
      );
      break;
        
    case MC_Cursed :
    case MC_Insectoid :
    case MC_Troll :
    case MC_Animal :
    case MC_Necrophage :
    case MC_Hybrid :
    case MC_Relic :
    case MC_Beast :
    case MC_Draconide :
    default :
      return (CEntityTemplate)LoadResourceAsync(
        "quests\generic_quests\skellige\quest_files\mh202_nekker_warrior\entities\mh202_nekker_tracks.w2ent",
        true
      );
  }
}
