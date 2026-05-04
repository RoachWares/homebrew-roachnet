cask "roachnet" do
  local_dmg = ENV.fetch("ROACHNET_CASK_LOCAL_DMG", nil)
  local_sha = ENV.fetch("ROACHNET_CASK_LOCAL_SHA", nil)

  version "1.0.4"
  sha256 local_dmg.to_s.empty? ? "ca600a2308a3a325fe386a60a953ada972b446d442ea61318f93fb1f02266692" : local_sha

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

  postflight do
    require "json"
    require "securerandom"
    require "socket"
    require "time"

    install_root = File.join(Dir.home, "RoachNet")
    app_path = File.join(install_root, "app", "RoachNet.app")
    setup_app_path = File.join(install_root, "setup", "RoachNet Setup.app")
    installer_assets_path = File.join(setup_app_path, "Contents", "Resources", "InstallerAssets")
    app_archive_path = Dir[File.join(installer_assets_path, "RoachNet-#{version}-mac-*.zip")].first
    source_archive_path = File.join(app_path, "Contents", "Resources", "RoachNetSource.tar.gz")
    source_root = File.join(install_root, "runtime", "bundled-source", version.to_s)
    source_staging_root = "#{source_root}.homebrew-staging-#{SecureRandom.hex(6)}"
    repo_path = File.join(source_root, "RoachNetSource")
    admin_path = File.join(repo_path, "admin")
    env_path = File.join(admin_path, ".env")
    storage_path = File.join(install_root, "storage")
    local_bin_path = File.join(install_root, "bin")
    runtime_state_root = File.join(storage_path, "state", "runtime-state")
    sqlite_db_path = File.join(storage_path, "state", "roachnet.sqlite")
    ollama_models_path = File.join(storage_path, "ollama")
    openclaw_workspace_path = File.join(storage_path, "openclaw")
    support_root = File.join(Dir.home, "Library", "Application Support", "roachnet")
    config_path = File.join(support_root, "roachnet-installer.json")
    legacy_config_path = File.join(Dir.home, ".roachnet-setup.json")
    embedded_node = File.join(app_path, "Contents", "Resources", "EmbeddedRuntime", "node", "bin", "node")
    embedded_npm = File.join(app_path, "Contents", "Resources", "EmbeddedRuntime", "node", "bin", "npm")
    roachtail_alias_installer = File.join(repo_path, "scripts", "install-roachtail-hostname.mjs")
    timestamp = Time.now.utc.iso8601
    resolve_port = lambda do |preferred_port|
      ([preferred_port] + (8081..8180).to_a).find do |candidate|
        begin
          server = TCPServer.new("127.0.0.1", candidate)
          server.close
          true
        rescue
          false
        end
      end || preferred_port
    end
    app_port = resolve_port.call(8080)

    raise "Missing RoachNet setup app at #{setup_app_path}" unless File.exist?(setup_app_path)
    raise "Missing embedded RoachNet app archive in #{installer_assets_path}" if app_archive_path.to_s.empty?

    FileUtils.mkdir_p(File.dirname(app_path))
    FileUtils.rm_rf(app_path)
    system "/usr/bin/ditto", "-x", "-k", app_archive_path, File.dirname(app_path)
    raise "Failed to extract RoachNet app to #{app_path}" unless File.exist?(app_path)
    raise "Missing bundled RoachNet source archive at #{source_archive_path}" unless File.exist?(source_archive_path)

    FileUtils.mkdir_p(File.dirname(source_root))
    FileUtils.rm_rf(source_root)
    FileUtils.rm_rf(source_staging_root)
    FileUtils.mkdir_p(source_staging_root)
    unless system "/usr/bin/tar", "-xzf", source_archive_path, "-C", source_staging_root
      FileUtils.rm_rf(source_staging_root)
      raise "Failed to extract RoachNet bundled source archive"
    end
    raise "Bundled source archive did not unpack RoachNetSource" unless File.exist?(File.join(source_staging_root, "RoachNetSource"))

    FileUtils.mv(source_staging_root, source_root)

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
    env_values = {
      "APP_KEY"                      => SecureRandom.hex(24),
      "DB_CONNECTION"                => "sqlite",
      "DB_DATABASE"                  => "roachnet",
      "DB_HOST"                      => "127.0.0.1",
      "DB_PASSWORD"                  => SecureRandom.hex(16),
      "DB_PORT"                      => "3306",
      "DB_SSL"                       => "false",
      "DB_USER"                      => "roachnet_user",
      "HOST"                         => "127.0.0.1",
      "LOG_LEVEL"                    => "info",
      "NODE_ENV"                     => "production",
      "OLLAMA_BASE_URL"              => "http://127.0.0.1:36434",
      "OLLAMA_MODELS"                => ollama_models_path,
      "OPENCLAW_BASE_URL"            => "http://127.0.0.1:13001",
      "OPENCLAW_WORKSPACE_PATH"      => openclaw_workspace_path,
      "PORT"                         => app_port.to_s,
      "REDIS_HOST"                   => "127.0.0.1",
      "REDIS_PORT"                   => "6379",
      "ROACHNET_CONTAINERLESS_MODE"  => "1",
      "ROACHNET_DB_ROOT_PASSWORD"    => SecureRandom.hex(16),
      "ROACHNET_DISABLE_QUEUE"       => "1",
      "ROACHNET_DISABLE_TRANSMIT"    => "1",
      "ROACHNET_LOCAL_BIN_PATH"      => local_bin_path,
      "ROACHNET_NODE_BINARY"         => embedded_node,
      "ROACHNET_NPM_BINARY"          => embedded_npm,
      "ROACHNET_RUNTIME_STATE_ROOT"  => runtime_state_root,
      "ROACHNET_STORAGE_PATH"        => storage_path,
      "SESSION_DRIVER"               => "cookie",
      "SQLITE_DB_PATH"               => sqlite_db_path,
      "URL"                          => "http://127.0.0.1:#{app_port}",
    }

    FileUtils.mkdir_p(support_root)
    FileUtils.mkdir_p(storage_path)
    FileUtils.mkdir_p(local_bin_path)
    FileUtils.mkdir_p(runtime_state_root)
    FileUtils.mkdir_p(File.dirname(sqlite_db_path))
    FileUtils.mkdir_p(ollama_models_path)
    FileUtils.mkdir_p(openclaw_workspace_path)
    FileUtils.mkdir_p(admin_path)
    File.write(config_path, "#{JSON.pretty_generate(config)}\n")
    File.write(legacy_config_path, "#{JSON.pretty_generate(config)}\n")
    File.write(env_path, env_values.sort.map { |key, value| "#{key}=#{value}" }.join("\n") + "\n")
    xattr_targets = [setup_app_path, app_path]
    [setup_app_path, app_path].each do |bundle_path|
      macos_dir = File.join(bundle_path, "Contents", "MacOS")
      if Dir.exist?(macos_dir)
        xattr_targets.concat(Dir.children(macos_dir).map { |entry| File.join(macos_dir, entry) })
      end
    end
    xattr_targets.each do |target|
      next unless File.exist?(target)

      system "/usr/bin/xattr", "-d", "com.apple.quarantine", target, out: File::NULL, err: File::NULL
      system "/usr/bin/xattr", "-d", "com.apple.provenance", target, out: File::NULL, err: File::NULL
    end
    system "/usr/bin/xattr", "-dr", "com.apple.provenance", setup_app_path, out: File::NULL, err: File::NULL
    system "/usr/bin/xattr", "-dr", "com.apple.quarantine", setup_app_path, out: File::NULL, err: File::NULL
    system "/usr/bin/xattr", "-cr", setup_app_path, out: File::NULL, err: File::NULL
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
      The setup app stays in ~/RoachNet/setup for repair installs.

      Launch it with:
        open ~/RoachNet/app/RoachNet.app
    EOS
  end
end
