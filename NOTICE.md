# NOTICE

This repository packages the proprietary software **MiniMax Code**,
which is © MiniMax.

- Use of MiniMax Code is subject to MiniMax's terms of service.
- This packaging does not grant any additional rights to MiniMax Code.
- The prebuilt `.deb` is downloaded at build time from
  [unfallenwill/minimax-code-linux](https://github.com/unfallenwill/minimax-code-linux)'s
  GitHub Releases and is not redistributed from this repository.

The packaging code (Nix expressions, `flake.nix`, scripts, README) in this
repository is licensed under the MIT License — see [LICENSE](./LICENSE).

"MiniMax" and "MiniMax Code" are trademarks of MiniMax, used here for
identification only.

This repository is **not** affiliated with, endorsed by, or sponsored by
MiniMax. For the official product, see https://agent.minimax.io.

## Credits

All of the actual packaging work — extracting the macOS `.dmg`,
matching the Linux Electron runtime, rebuilding native addons — is done
by [unfallenwill](https://github.com/unfallenwill) in
[unfallenwill/minimax-code-linux](https://github.com/unfallenwill/minimax-code-linux).
This Nix packaging only consumes the `.deb` artifacts published from
that repository; without unfallenwill's work, this repository would not
exist.
