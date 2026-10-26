# Helios OS

Debian 13 base, KDE Plasma (Wayland), Btrfs + snapshots, Flatpak-first apps, `helium` package manager, optional custom kernel.
**Untested draft.** Live login: user / live.

## Build the ISO
- Easiest: upload this folder to a GitHub repo -> Actions -> "build-iso" -> Run workflow. ISO appears under the run's artifacts.
- Or on Debian 13:  `sudo ./auto/config && sudo lb build`
- Tick `custom_kernel` in the workflow (or build with `HELIOS_KERNEL=<contents of kernel-out/KERNELRELEASE>` after running `kernel/build-kernel.sh` and copying the .debs into `config/packages.chroot/`) to use the Helios kernel instead of Debian's.

## helium (package manager)
Apps are Flatpaks. `helium` searches the Helios repo first, then Flathub.

    helium search media          helium install firefox vlc
    helium remove vlc            helium update
    helium list                  helium info firefox
    helium run firefox           helium clean
    helium remote add NAME URL   helium doctor

Default apps installed on first boot are listed in `/etc/helium/default-apps.list` (edit in `config/includes.chroot_after_packages/etc/helium/`).

## Publishing your own apps to helium
1. Package each app as a Flatpak bundle (`flatpak-builder` ... then `flatpak build-bundle repo myapp.flatpak org.example.MyApp`). Learn how at docs.flatpak.org.
2. Create and fill the repo:

       helium repo init   ~/helios-apps
       helium repo add    ~/helios-apps myapp.flatpak other.flatpak
       gpg --quick-generate-key 'Helios Apps <apps@example.org>'      # once
       helium repo update ~/helios-apps --gpg-sign YOURKEYID
       gpg --export YOURKEYID > helios-apps.gpg

3. Upload the `~/helios-apps/repo` folder to any static host (GitHub Pages, Cloudflare Pages, S3).
4. Generate the source file and put it in the project:

       helium repo repofile ~/helios-apps --url https://YOUR-HOST/repo --gpg-key helios-apps.gpg

   Replace `config/includes.chroot_after_packages/etc/helium/helium.flatpakrepo` with the generated `helium.flatpakrepo`, then rebuild.
   Existing installs can add it live: `sudo helium remote add helium https://YOUR-HOST/helium.flatpakrepo`
5. Users then run `helium install myapp`.

## Custom kernel
`kernel/build-kernel.sh` builds a tuned Linux kernel (default source: Linux 7.3, `7.3.0-helios`) as `.deb` packages:
1000 Hz timer, full preemption, BBR networking, zswap/zstd, no debug info. It starts from Debian's stock kernel config
and applies `kernel/helios.fragment`; add patches in `kernel/patches/`. It is a configured Linux kernel, not a from-scratch one.

- GitHub: run the workflow with `custom_kernel` ticked. It downloads the source from kernel.org (no need to upload the tarball).
- Local: `sudo KERNEL_TARBALL=/path/to/linux-7.3.tar.xz bash kernel/build-kernel.sh`

Know before you ship it:
- Linux 7.3 is a short-lived release, not an LTS. It stops getting fixes after a few months, so you must rebase to the next kernel regularly. For something long-lived, use `KVER=6.12.<N>` (Debian's own LTS series) instead.
- Debian 13's NVIDIA proprietary driver will probably not build against 7.3. Expect Intel/AMD/nouveau only until Debian ships a newer driver.
- The kernel is NOT signed, so it will not boot with Secure Boot on.
- Test with the stock kernel first.
