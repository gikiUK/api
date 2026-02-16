# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the first user
ihid_user = User.find_or_create_by!(email: "ihid@giki.io") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end
ihid_user.confirm
puts "Created user: #{ihid_user.email}"

# Create the admin user
aron_user = User.find_or_create_by!(email: "aron@giki.io") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end
aron_user.update!(admin: true)
aron_user.confirm
puts "Created admin user: #{aron_user.email}"

# Seed the initial live facts dataset
# Note: uses where().exists? instead of FactsDataset.live because .live raises if not found
unless FactsDataset.where(status: "live").exists?
  seed_dir = Rails.root.join("db/seeds")

  # --- Constants ---
  # Convert from old format (BUSINESS_SIZE_OPTIONS => ["Self Employed", ...])
  # to blob format (business_size => [{ id: 1, name: "Self Employed", ... }])
  GROUP_KEY_MAP = {
    "BUSINESS_SIZE_OPTIONS" => "business_size",
    "MEASURES_EMISSIONS_OPTIONS" => "measures_emissions",
    "REDUCTION_TARGETS_OPTIONS" => "reduction_targets",
    "BUILDING_TYPE_OPTIONS" => "building_type",
    "SUPPLY_CHAIN_CHALLENGE_OPTIONS" => "supply_chain_challenge",
    "INDUSTRY_OPTIONS" => "industry"
  }.freeze

  raw_constants = JSON.parse(File.read(seed_dir.join("constants.json")))
  constants = {}
  # Build a lookup: { "industry" => { "Advertising" => 1, ... }, "business_size" => { "Self Employed" => 1, ... } }
  value_id_lookup = {}

  raw_constants.each do |old_key, values|
    group_key = GROUP_KEY_MAP.fetch(old_key)
    value_id_lookup[group_key] = {}

    constants[group_key] = values.each_with_index.map do |val, idx|
      id = idx + 1
      # INDUSTRY_OPTIONS has { label, value } shape; others are plain strings
      name = val.is_a?(Hash) ? val["value"] : val
      label = val.is_a?(Hash) ? val["label"] : val
      value_id_lookup[group_key][name] = id
      { "id" => id, "name" => name, "label" => label, "description" => nil, "enabled" => true }
    end
  end

  # Helper to convert string references in conditions to numeric IDs
  convert_condition_values = lambda do |condition|
    return condition unless condition.is_a?(Hash)

    condition.transform_values do |v|
      if v.is_a?(Array) && v.first.is_a?(String)
        # Could be industry names or size names — try to resolve
        resolved = v.filter_map do |str|
          value_id_lookup.values.filter_map { |lookup| lookup[str] }.first
        end
        resolved.empty? ? v : resolved
      elsif v.is_a?(Hash) && v.key?("any")
        { "any" => v["any"].map { |c| convert_condition_values.call(c) } }
      else
        v
      end
    end
  end

  # --- Facts ---
  raw_facts = JSON.parse(File.read(seed_dir.join("facts.json")))["facts"]
  facts = raw_facts.transform_values do |fact|
    fact = fact.merge("enabled" => true)
    if fact["values_ref"]
      fact["values_ref"] = GROUP_KEY_MAP.fetch(fact["values_ref"])
    end
    fact
  end

  # --- Questions ---
  raw_questions = JSON.parse(File.read(seed_dir.join("questions.json")))["questions"]
  questions = raw_questions.map do |q|
    q = q.merge("enabled" => true)
    if q["options_ref"]
      q["options_ref"] = GROUP_KEY_MAP.fetch(q["options_ref"])
    end
    q["show_when"] = convert_condition_values.call(q["show_when"]) if q["show_when"]
    q["hide_when"] = convert_condition_values.call(q["hide_when"]) if q["hide_when"]
    q
  end

  # --- Rules ---
  # Hotspot rules first (higher precedence), then general rules
  hotspot_rules = JSON.parse(File.read(seed_dir.join("hotspot_rules.json")))["rules"]
  general_rules = JSON.parse(File.read(seed_dir.join("general_rules.json")))["rules"]

  rules = hotspot_rules.map do |r|
    r.merge("source" => "hotspot", "enabled" => true, "when" => convert_condition_values.call(r["when"]))
  end + general_rules.map do |r|
    r.merge("source" => "general", "enabled" => true, "when" => convert_condition_values.call(r["when"]))
  end

  # --- Actions + Action Conditions ---
  raw_actions = JSON.parse(File.read(seed_dir.join("actions.json")))
  action_conditions = {}
  raw_actions.each do |raw_action|
    action = Action.find_or_create_by!(airtable_id: raw_action["airtable_id"]) do |a|
      a.title = raw_action["title"]
    end
    action_conditions[action.id.to_s] = {
      "enabled" => true,
      "include_when" => convert_condition_values.call(raw_action["include_when"] || {}),
      "exclude_when" => convert_condition_values.call(raw_action["exclude_when"] || {})
    }
  end

  # --- Build the blob ---
  data = {
    "facts" => facts,
    "questions" => questions,
    "rules" => rules,
    "constants" => constants,
    "action_conditions" => action_conditions
  }

  FactsDataset.create!(status: "live", data: data, test_cases: [])
  puts "Created live facts dataset (#{facts.size} facts, #{questions.size} questions, #{rules.size} rules, #{action_conditions.size} action conditions)"
  puts "Created #{Action.count} actions"
end
