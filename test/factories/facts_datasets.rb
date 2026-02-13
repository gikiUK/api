FactoryBot.define do
  factory :facts_dataset do
    status { "live" }
    data do
      {
        facts: {},
        questions: [],
        rules: [],
        constants: {},
        action_conditions: {}
      }
    end
    test_cases { [] }

    trait :draft do
      status { "draft" }
    end

    trait :live do
      status { "live" }
    end

    trait :archived do
      status { "archived" }
    end

    trait :with_test_cases do
      test_cases do
        [
          {
            name: "Small advertising agency",
            input_facts: { size: 2, industries: [ 1 ], owns_buildings: true },
            expected_actions: %w[action_key_1 action_key_2]
          }
        ]
      end
    end

    trait :with_data do
      data do
        {
          facts: {
            has_company_vehicles: { type: "boolean_state", core: true, category: "transport-travel", enabled: true },
            size: { type: "enum", core: true, values_ref: "business_size", enabled: true }
          },
          questions: [
            {
              type: "boolean_state",
              label: "Does your company own or lease any vehicles?",
              fact: "has_company_vehicles",
              enabled: true
            }
          ],
          rules: [
            { sets: "uses_buildings", value: true, source: "general", when: { any: [ { owns_buildings: true } ] }, enabled: true }
          ],
          constants: {
            industry: [
              { id: 1, name: "Advertising", description: nil, enabled: true },
              { id: 2, name: "Broadcasting", description: nil, enabled: true }
            ],
            business_size: [
              { id: 1, name: "Self Employed", description: "Sole traders", enabled: true },
              { id: 2, name: "Small", description: "10-50 employees", enabled: true }
            ]
          },
          action_conditions: {
            action_key_1: {
              enabled: true,
              include_when: { cat_6_relevant: true },
              exclude_when: {}
            }
          }
        }
      end
    end
  end
end
