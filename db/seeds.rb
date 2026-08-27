[ "Cyp", "Multybeauty" ].each do |source_name|
  MerchantSource.find_or_create_by!(name: source_name)
end
