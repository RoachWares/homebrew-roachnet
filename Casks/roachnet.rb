cask "roachnet" do
  local_dmg = ENV.fetch("ROACHNET_CASK_LOCAL_DMG", nil)
  local_sha = ENV.fetch("ROACHNET_CASK_LOCAL_SHA", nil)

  version "1.1.3"
  sha256 local_dmg.to_s.empty? ? "f514fee7574bc77991d2461ddbeb030a6e0abe1d45b473c609753f364cbfea74" : local_sha

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
    install_root = File.join(Dir.home, "RoachNet")
    setup_app_path = File.join(install_root, "setup", "RoachNet Setup.app")
    installer = File.join(setup_app_path, "Contents", "Helpers", "roachnet-runtime")

    raise "Missing RoachNet setup app at #{setup_app_path}" unless File.exist?(setup_app_path)
    raise "RoachNet Setup #{version} is missing its native installer at #{installer}" unless File.executable?(installer)

    %w[com.apple.quarantine com.apple.provenance].each do |attribute|
      system "/usr/bin/xattr", "-dr", attribute, setup_app_path, out: File::NULL, err: File::NULL
    end

    system(
      {
        "ROACHNET_SETUP_APP_BUNDLE" => setup_app_path,
        "ROACHNET_LOCAL_HOSTNAME"   => "RoachNet",
      },
      installer, "--install",
      "--install-path", install_root,
      "--profile", "homebrew-cask",
      "--no-companion"
    )
    status = Process.last_status

    again = "open \"#{setup_app_path}\" or run `brew reinstall --cask roachnet`"
    if status&.success?
      nil
    elsif status&.signaled?
      opoo "RoachNet Setup was stopped by signal #{status.termsig} before it finished. " \
           "Your files are kept; to finish installing, #{again}."
    elsif status&.exitstatus == 75
      opoo "RoachNet Setup didn't install: another RoachNet Setup is running, or Setup can't use its " \
           "lock file (see its message above). Nothing was changed. When that is fixed, #{again}."
    elsif status&.exitstatus == 65
      opoo "RoachNet Setup stopped without installing anything or deleting your files. " \
           "Its message above says what to fix; then #{again}."
    else
      raise "RoachNet install failed#{" (exit #{status.exitstatus})" if status&.exitstatus}. " \
            "Open #{setup_app_path} to repair the install."
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
