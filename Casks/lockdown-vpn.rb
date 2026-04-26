cask "lockdown-vpn" do
  version "0.1.0"
  sha256 "9fe904442a985d0526a2b8ce07d35fe5e2bb1d412227f54a2a4e3dab608caec8"

  url "https://github.com/maksimzinchuk/lockdown/releases/download/v#{version}/Lockdown-#{version}.zip",
      verified: "github.com/maksimzinchuk/lockdown/"
  name "Lockdown"
  desc "VPN kill switch for macOS that blocks egress on the physical NIC via PF"
  homepage "https://github.com/maksimzinchuk/lockdown"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "Lockdown.app"

  # The release build is not Apple-notarized. macOS attaches a quarantine
  # xattr to anything downloaded by Homebrew, which makes Gatekeeper refuse
  # to open the app on first launch. Stripping it here is the same thing
  # the user would otherwise be told to do via the terminal.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Lockdown.app"],
                   sudo: false
  end

  uninstall launchctl: "ru.symbot.lockdown",
            delete:    [
              "/Library/LaunchDaemons/ru.symbot.lockdown.plist",
              "/Library/LaunchAgents/ru.symbot.lockdown.menubar.plist",
              "/usr/local/bin/lockdown",
              "/etc/pf.anchors/lockdown",
            ]

  # Note: the daemon also patches /etc/pf.conf with an `anchor "lockdown"`
  # line. `sudo lockdown uninstall` removes that line cleanly; `brew
  # uninstall` cannot, because zap/uninstall blocks run as the user and
  # editing /etc/pf.conf needs root. Users wanting a complete removal
  # should run `sudo lockdown uninstall` BEFORE `brew uninstall lockdown`.

  zap trash: [
    "~/Library/Application Support/Lockdown",
    "~/Library/Preferences/ru.symbot.lockdown.plist",
  ]

  caveats <<~EOS
    Lockdown installs a privileged daemon that manages PF firewall rules.
    On first launch the app will prompt for admin credentials to install
    the daemon under /usr/local/bin/lockdown and register the launchd job.

    The release build is not Apple-notarized — Homebrew strips the
    quarantine attribute automatically (see postflight). If you prefer
    to verify the binary yourself, the SHA-256 in this cask is published
    in the GitHub release notes.

    To remove every trace, run BEFORE `brew uninstall`:
      sudo lockdown uninstall
  EOS
end
