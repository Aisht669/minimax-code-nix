# minimax-code-nix

非官方 [Nix](https://nixos.org/) 打包,让 [MiniMax Code](https://agent.minimax.io) 能在 NixOS 上跑。

## 🙏 基于 [unfallenwill/minimax-code-linux](https://github.com/unfallenwill/minimax-code-linux)

所有难活 —— 把 macOS `.dmg` 拆开、跨平台 Electron runtime 对接、原生模块 rebuild —— 都是 [unfallenwill](https://github.com/unfallenwill) 在那个仓库里干的。本仓库只是把 upstream 出的 `.deb` 套上 `buildFHSEnv` 重新打进 Nix store,**没有 unfallenwill 的 upstream 工作,这个仓库根本不存在**。

## 工作原理(2 句话)

1. 从 [unfallenwill/minimax-code-linux](https://github.com/unfallenwill/minimax-code-linux) 的 GitHub Release 拉 `.deb`
2. 拆开,用 `buildFHSEnv`(bubblewrap 后端)装进 FHS 沙箱,加 Wayland / XDG / scheme handler 处理,输出一个 Nix-native 包

不用改 `/usr`,不依赖 setuid,纯 declarative。

## ⚠️ 非官方 / 法律

- **MiniMax Code 是 MiniMax 的专有产品**,本仓库不重新分发其源码,只打包已发布的 `.deb`。
- 本仓库**与 MiniMax 无任何关联**。
- 打包代码本身是 MIT。详见 [LICENSE](./LICENSE) 和 [NOTICE.md](./NOTICE.md)。

## 安装

### A. 作为 flake input(推荐)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    minimax-code-nix.url = "github:Aisht669/minimax-code-nix";
  };

  outputs = { nixpkgs, minimax-code-nix, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;
          environment.systemPackages = [
            minimax-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.minimax-code
          ];
        })
      ];
    };
  };
}
```

### B. 用 overlay

```nix
nixpkgs.overlays = [ minimax-code-nix.overlays.default ];
# 然后 pkgs.minimax-code 就有了
```

### C. 直接 nix run 试一下

```bash
nix run github:Aisht669/minimax-code-nix
```

## 用法

```bash
minimax-code
```

或者从应用菜单(niri / sway / Hyprland / GNOME / KDE 等已自动注册 .desktop)。

第一次启动会下载 MiniMax 的 agent binary,需要联网。

## NixOS 特殊处理说明

| 项 | 处理 |
|---|---|
| `chrome-sandbox` (setuid) | NixOS 不允许 store 文件 setuid,直接 `--no-sandbox --disable-setuid-sandbox` |
| Wayland | 启动器检测 `WAYLAND_DISPLAY` / `XDG_SESSION_TYPE`,自动走 Ozone 后端 |
| URL scheme `minimax-cn://` / `minimax://` | `.desktop` 注册为 handler,浏览器 OAuth 回调能激活 app |
| XDG 桌面集成 | `makeDesktopItem` 重写 Exec,fuzzel 等启动器能拉起 |

## GPU 加速

默认包含 `mesa` + `libglvnd`,AMD/Intel 集显应该 OK。

NVIDIA 独显用户需要额外加 NVIDIA 用户态到 `electronRuntime`(否则 fall back 到 SwiftShader 软渲染,会卡)。改 `package.nix`:

```nix
electronRuntime = [
  ...
  # 加这一行
  pkgs.linuxPackages.nvidiaPackages.stable
];
```

## 升级

改 `package.nix` 里 `version = "3.0.67";`,然后让 Nix 报真实 hash:

```bash
nix-prefetch-url --type sha256 \
  https://github.com/unfallenwill/minimax-code-linux/releases/download/minimax-code-v<新版本>/minimax-code_<新版本>_amd64.deb
```

填进 `sha256 = "sha256-...";`。

## 已知日志噪音(都是无害的)

- `HotUpdate Manifest appVersion X does not match Y` —— 上游热更新不匹配,正常运行
- `Insecure Content-Security-Policy` —— 上游 CSP 没设严,Electron 警告
- Wayland 几个 `Server doesn't support zcr_alpha_compositing_v1` 等 —— 等 compositor 升级

## License

- 打包代码:MIT — [LICENSE](./LICENSE)
- MiniMax Code 本身:© MiniMax,专有 — [NOTICE.md](./NOTICE.md)

## Credits

- **[unfallenwill/minimax-code-linux](https://github.com/unfallenwill/minimax-code-linux)** — upstream Linux 打包流水线,本仓库 100% 依赖其发布的 `.deb`
- **[MiniMax](https://agent.minimax.io)** — MiniMax Code 本身
- **[NixOS](https://nixos.org/)** — Nix / NixOS / `buildFHSEnv`
