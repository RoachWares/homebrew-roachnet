cask "roachnet" do
  local_dmg = ENV.fetch("ROACHNET_CASK_LOCAL_DMG", nil)
  local_sha = ENV.fetch("ROACHNET_CASK_LOCAL_SHA", nil)

  version "1.0.4"
  sha256 local_dmg.to_s.empty? ? "d1eff45747f8538bc7d3b01c1655f72f755f328301b2a14d75893ba68372192f" : local_sha

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

  app "RoachNet.app",
      target: "#{Dir.home}/RoachNet/app/RoachNet.app"

  postflight do
    require "json"
    require "securerandom"
    require "time"

    install_root = File.join(Dir.home, "RoachNet")
    app_path = File.join(install_root, "app", "RoachNet.app")
    storage_path = File.join(install_root, "storage")
    local_bin_path = File.join(install_root, "bin")
    support_root = File.join(Dir.home, "Library", "Application Support", "roachnet")
    config_path = File.join(support_root, "roachnet-installer.json")
    legacy_config_path = File.join(Dir.home, ".roachnet-setup.json")
    embedded_node = File.join(app_path, "Contents", "Resources", "EmbeddedRuntime", "node", "bin", "node")
    roachtail_alias_installer = File.join(
      app_path,
      "Contents",
      "Resources",
      "RoachNetSource",
      "scripts",
      "install-roachtail-hostname.mjs"
    )
    timestamp = Time.now.utc.iso8601

    config = {
      "installPath"                 => install_root,
      "installedAppPath"            => app_path,
      "storagePath"                 => storage_path,
      "installProfile"              => "homebrew-cask",
      "useDockerContainerization"   => false,
      "installRoachClaw"            => true,
      "companionEnabled"            => false,
      "companionHost"               => "127.0.0.1",
      "companionPort"               => 38111,
      "companionToken"              => SecureRandom.hex(32),
      "companionAdvertisedURL"      => "",
      "roachClawDefaultModel"       => "qwen2.5-coder:1.5b",
      "distributedInferenceBackend" => "disabled",
      "exoBaseUrl"                  => "http://127.0.0.1:52415",
      "exoModelId"                  => "",
      "autoInstallDependencies"     => false,
      "autoLaunch"                  => true,
      "releaseChannel"              => "stable",
      "setupCompletedAt"            => timestamp,
      "bootstrapPending"            => true,
      "bootstrapFailureCount"       => 0,
      "lastRuntimeHealthAt"         => nil,
      "pendingLaunchIntro"          => false,
      "pendingRoachClawSetup"       => true,
    }

    FileUtils.mkdir_p(support_root)
    FileUtils.mkdir_p(storage_path)
    FileUtils.mkdir_p(local_bin_path)
    File.write(config_path, "#{JSON.pretty_generate(config)}\n")
    File.write(legacy_config_path, "#{JSON.pretty_generate(config)}\n")
    xattr_targets = [app_path]
    macos_dir = File.join(app_path, "Contents", "MacOS")
    if Dir.exist?(macos_dir)
      xattr_targets.concat(Dir.children(macos_dir).map { |entry| File.join(macos_dir, entry) })
    end
    xattr_targets.each do |target|
      next unless File.exist?(target)

      system "/usr/bin/xattr", "-d", "com.apple.quarantine", target, out: File::NULL, err: File::NULL
      system "/usr/bin/xattr", "-d", "com.apple.provenance", target, out: File::NULL, err: File::NULL
    end
    system "/usr/bin/xattr", "-dr", "com.apple.provenance", app_path, out: File::NULL, err: File::NULL
    system "/usr/bin/xattr", "-dr", "com.apple.quarantine", app_path, out: File::NULL, err: File::NULL
    system "/usr/bin/xattr", "-cr", app_path, out: File::NULL, err: File::NULL
    if File.exist?(embedded_node) && File.exist?(roachtail_alias_installer)
      system(
        {
          "ROACHNET_LOCAL_HOSTNAME" => "RoachNet",
        },
        embedded_node,
        roachtail_alias_installer,
        "--interactive",
      )
    end
  end

  zap trash: [
    "~/.roachnet-setup.json",
    "~/Library/Application Support/roachnet",
    "~/RoachNet",
  ]

  caveats do
    <<~EOS
      RoachNet installs into ~/RoachNet/app/RoachNet.app so the native app, vault, and local tools stay grouped together.

      Launch it with:
        open ~/RoachNet/app/RoachNet.app
    EOS
  end
end
