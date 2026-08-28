# minimax-code-nix/package.nix
#
# MiniMax Code 的非官方 Nix 打包。
#
# 来源:把 unfallenwill/minimax-code-linux 发布的 .deb 拆开,
#       用 buildFHSEnv(bubblewrap 后端)重新装进 FHS 沙箱,
#       在 NixOS 上能跑,不用碰 /usr,也不用 setuid store 文件。
#
# 协议:本打包代码 MIT。MiniMax Code 自身 © MiniMax,专有。
#      详见 NOTICE.md。

{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  buildFHSEnv,
  makeDesktopItem,
  symlinkJoin,
  writeShellScript,

  # X11 / Wayland
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxshmfence,
  libxtst,
  libxkbcommon,

  # GL / EGL
  libglvnd,
  mesa,

  # Electron 运行时
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libnotify,
  libsecret,
  libxcb,
  nspr,
  nss,
  pango,
  udev,
}:

let
  version = "3.0.67";

  src = fetchurl {
    url = "https://github.com/unfallenwill/minimax-code-linux/releases/download/minimax-code-v${version}/minimax-code_${version}_amd64.deb";
    sha256 = "sha256-jqMyrcO3ZxauRq7gQMmhPkzu87IMJLaY9AXmkKhuTb0=";
  };

  # 拆 .deb:opt/ 给 fhsenv 用,usr/ 后面给桌面集成用
  payload = stdenv.mkDerivation {
    pname = "minimax-code-payload";
    inherit version src;
    nativeBuildInputs = [ dpkg ];
    dontConfigure = true;
    dontBuild = true;
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a usr/. $out/
      cp -a opt/. $out/opt/
      runHook postInstall
    '';
  };

  # Electron 二进制在 NixOS 上的运行时依赖集
  electronRuntime = [
    alsa-lib at-spi2-atk at-spi2-core atk cairo cups dbus expat
    gdk-pixbuf glib gtk3 libdrm libgbm libglvnd libnotify libsecret
    libxcb libxkbcommon libxshmfence mesa nspr nss pango udev
    libx11 libxcomposite libxdamage libxext libxfixes libxrandr libxtst
  ];

  # 启动器:Wayland 优先 + 关 sandbox(NixOS store 只读,setuid 做不了)
  launcher = writeShellScript "minimax-code-launcher" ''
    set -e
    export ELECTRON_ENABLE_LOGGING="''${ELECTRON_ENABLE_LOGGING:-1}"

    SANDBOX_ARGS="--no-sandbox --disable-setuid-sandbox"

    OZONE_FLAGS=""
    if [ -n "''${WAYLAND_DISPLAY:-}" ] || [ "''${XDG_SESSION_TYPE:-}" = "wayland" ]; then
      OZONE_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland"
    fi

    exec ${payload}/opt/minimax-code/electron \
      $SANDBOX_ARGS $OZONE_FLAGS --class=minimax-code "$@"
  '';

  # FHS 沙箱,提供 bin/minimax-code wrapper
  fhsEnv = buildFHSEnv {
    name = "minimax-code";
    targetPkgs = pkgs: electronRuntime;
    runScript = launcher;
  };

  # Nix-native 桌面项:Exec 指绝对 store 路径,不走 PATH,
  # fuzzel / rofi-wayland / 浏览器 scheme handler 都认
  desktopItem = makeDesktopItem {
    name = "minimax-code";
    desktopName = "MiniMax Code";
    genericName = "AI Coding Agent";
    comment = "MiniMax Code (unofficial Linux package)";
    exec = "${fhsEnv}/bin/minimax-code %U";
    icon = "minimax-code";
    startupNotify = true;
    startupWMClass = "minimax-code";
    categories = [ "Development" "IDE;Utility;" ];
    terminal = false;
    mimeTypes = [
      "x-scheme-handler/minimax-cn"
      "x-scheme-handler/minimax"
    ];
  };
in
symlinkJoin {
  name = "minimax-code";
  paths = [ fhsEnv desktopItem ];

  meta = {
    description = "MiniMax Code (unofficial Nix packaging)";
    longDescription = ''
      Non-Nix-friendly Electron application packaged from
      unfallenwill/minimax-code-linux's prebuilt .deb for use on NixOS.

      Not affiliated with MiniMax. MiniMax Code is © MiniMax, proprietary.
      This packaging only repackages the existing upstream .deb so it
      can be installed on NixOS without modifying /usr or relying on
      setuid bits.

      Upstream: https://github.com/unfallenwill/minimax-code-linux
    '';
    homepage = "https://github.com/unfallenwill/minimax-code-linux";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "minimax-code";
  };
}
