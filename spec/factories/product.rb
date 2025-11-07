FactoryBot.define do
  factory :product do
    name { "TestProduct" }
    cost { 100 }
    image_url { "picsum.photos/200/300" }
  end
end
