def vite_asset_path(asset)
  prefix = 'vite'

  manifest = JSON.parse(File.read(File.join(settings.public_dir, "#{prefix}/.vite", 'manifest.json')))
  entry = manifest.fetch("entrypoints/#{asset}")

  "/#{prefix}/#{entry['file']}"
end
