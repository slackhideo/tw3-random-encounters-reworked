
function displayRandomEncounterEnabledNotification() {
  theGame
  .GetGuiManager()
  .ShowNotification(
    GetLocStringByKey("option_rer_enabled")
  );
}

function displayRandomEncounterDisabledNotification() {
  theGame
  .GetGuiManager()
  .ShowNotification(
    GetLocStringByKey("option_rer_disabled")
  );
}

function NDEBUG(message: string, optional duration: float) {
  theGame
  .GetGuiManager()
  .ShowNotification(message, duration);
}

function NHUD(message: string) {
  thePlayer.DisplayHudMessage(message);
}

function NLOG(message: string) {
  LogChannel('RER', message);
}

function NTUTO(title: string, body: string, optional do_not_pause: bool) {
  var tut: W3TutorialPopupData;

  tut = new W3TutorialPopupData in thePlayer;

  tut.managerRef = theGame.GetTutorialSystem();
  tut.messageTitle = title;
  tut.messageText = body;

  // You can even add images if you want, i didn't test it however
  // tut.imagePath = tutorialEntry.GetImagePath();

  tut.enableGlossoryLink = false;
  tut.autosize = true;
  tut.blockInput = !do_not_pause;
  tut.pauseGame = !do_not_pause;
  tut.fullscreen = true;
  tut.canBeShownInMenus = true;

  tut.duration = -1; // input
  tut.posX = 0;
  tut.posY = 0;
  tut.enableAcceptButton = true;
  tut.fullscreen = true;

  if (do_not_pause) {
    tut.blockInput = false;
    tut.pauseGame = false;
    tut.enableAcceptButton = false;
    tut.duration = 10;
  }

  theGame.GetTutorialSystem().ShowTutorialHint(tut);
}

function RER_toggleHUD() {
  var hud : CR4ScriptedHud;

  hud = (CR4ScriptedHud)theGame.GetHud();

  if ( hud )
  {
    hud.ToggleHudByUser();
  }
}