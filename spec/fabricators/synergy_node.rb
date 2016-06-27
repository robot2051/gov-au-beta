Fabricator(:synergy_node) do
  title { Fabricate.sequence(:title) { |i| "Some Title #{i}" } }
  path { Fabricate.sequence(:path) { |i| "path-#{i}" } }
  content { Fabricate.sequence(:content) { |i| { body: "Random content #{i}" }} }
end
