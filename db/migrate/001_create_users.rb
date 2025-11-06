Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :email, null: false, unique: true
      String :password_digest, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:users)
  end
end