class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      # Authentication
      t.string :name, null: false, default: ''
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :password_salt, null: false

      # Confirmation
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at

      # Password Reset
      t.string :reset_password_token
      t.datetime :reset_password_token_sent_at

      # Locked account
      t.integer :failed_attempts
      t.string :unlock_token
      t.datetime :locked_at

      # Token auth
      t.string :tokens, limit: 1024

      t.timestamps null: false
    end
    add_index :users, :email, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
  end
end
