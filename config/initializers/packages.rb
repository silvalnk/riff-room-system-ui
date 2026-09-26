%w[presence appreciation performance booth].each do |name|
  root = Rails.root.join("packages/#{name}/lib")
  $LOAD_PATH.unshift(root.to_s) unless $LOAD_PATH.include?(root.to_s)
  Dir[root.join("{domain,application}/**/*.rb")].sort.each { |file| require file }
end
