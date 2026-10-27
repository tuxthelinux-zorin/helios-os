// Helios Glass default layout: floating top bar + floating glass dock + aurora wallpaper.
function trySet(o, k, v) { try { o[k] = v; } catch (e) {} }

try {
  var ds = desktops();
  for (var i = 0; i < ds.length; i++) {
    var d = ds[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/HeliosGlass");
  }
} catch (e) {}

// ---- top bar
var topBar = new Panel;
topBar.location = "top";
topBar.height = 32;
trySet(topBar, "floating", true);
topBar.addWidget("org.kde.plasma.appmenu");
topBar.addWidget("org.kde.plasma.panelspacer");
topBar.addWidget("org.kde.plasma.systemtray");
topBar.addWidget("org.kde.plasma.digitalclock");

// ---- glass dock
var dock = new Panel;
dock.location = "bottom";
dock.height = 62;
dock.alignment = "center";
trySet(dock, "lengthMode", "fit");
trySet(dock, "floating", true);
trySet(dock, "hiding", "dodgewindows");
dock.addWidget("org.kde.plasma.kickoff");
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
  "applications:org.kde.dolphin.desktop",
  "applications:org.mozilla.firefox.desktop",
  "applications:org.kde.konsole.desktop",
  "applications:systemsettings.desktop"
]);
