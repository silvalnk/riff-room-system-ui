Rails.application.config.assets.paths.unshift Rails.root.join("app/assets/builds")

if Rails.env.development?
  built = system("npm", "run", "build:ts", "--silent", chdir: Rails.root.to_s)
  Rails.logger.warn("TypeScript build failed. Run npm install && npm run build:ts") unless built
end
