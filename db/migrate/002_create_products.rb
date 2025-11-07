Sequel.migration do
  up do
    create_table(:products) do
      primary_key :id
      String :name, null: false
      Text :description
      BigDecimal :cost, size: [10, 2], null: false, default: 0
      String :image_url
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:products)
  end
end
