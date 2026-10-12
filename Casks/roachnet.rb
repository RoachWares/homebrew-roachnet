cask "roachnet" do
  local_dmg = ENV.fetch("ROACHNET_CASK_LOCAL_DMG", nil)
  local_sha = ENV.fetch("ROACHNET_CASK_LOCAL_SHA", nil)

  version "1.1.0"
  sha256 local_dmg.to_s.empty? ? "d7854ac9960ed8969e24db9f7e95d18df8b80c2d2333eaa7f164bb1c4a6f66bd" : local_sha

  url local_dmg.to_s.empty? ? "https://github.com/RoachWares/RoachNet/releases/download/v#{version}/RoachNet-Setup-macOS.dmg" : "file://#{local_dmg}",
      verified: local_dmg.to_s.empty? ? "github.com/RoachWares/RoachNet/" : nil
  name "RoachNet"
  desc "Local-first desktop command center for maps, models, and vaults"
  homepage "https://roachnet.org/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "RoachNet Setup.app",
      target: "#{Dir.home}/RoachNet/setup/RoachNet Setup.app"

  # 1.0.6+: RoachNet Setup carries the native Swift installer
  # (Contents/Helpers/roachnet-runtime). The cask runs the same staged install the
  # Setup app uses (preflight, runtime smoke test, root swap with storage
  # preservation, RoachTail alias) — no Node, source tree, or .env files. 1.1+
  # installs no model runner: RoachClaw runs on RoachInference inside the helper.
  postflight do
    install_root = File.join(Dir.home, "RoachNet")
    setup_app_path = File.join(install_root, "setup", "RoachNet Setup.app")
    installer = File.join(setup_app_path, "Contents", "Helpers", "roachnet-runtime")

    raise "Missing RoachNet setup app at #{setup_app_path}" unless File.exist?(setup_app_path)
    raise "RoachNet Setup #{version} is missing its native installer at #{installer}" unless File.executable?(installer)

    %w[com.apple.quarantine com.apple.provenance].each do |attribute|
      system "/usr/bin/xattr", "-dr", attribute, setup_app_path, out: File::NULL, err: File::NULL
    end

    installed = system(
      {
        "ROACHNET_SETUP_APP_BUNDLE" => setup_app_path,
        "ROACHNET_LOCAL_HOSTNAME"   => "RoachNet",
      },
      installer, "--install",
      "--install-path", install_root,
      "--profile", "homebrew-cask",
      "--no-companion"
    )
    raise "RoachNet install failed. Open #{setup_app_path} to repair the install." unless installed
  end

  zap trash: [
    "~/.roachnet-setup.json",
    "~/Library/Application Support/roachnet",
    "~/RoachNet",
  ]

  caveats do
    <<~EOS
      RoachNet installs into ~/RoachNet/app/RoachNet.app so the native app, vault, and local tools stay grouped together.
      The setup app stays in ~/RoachNet/setup for repair installs.

      Launch it with:
        open ~/RoachNet/app/RoachNet.app
    EOS
  end
end
