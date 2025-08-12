class CreateUsersForTesting < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.boolean :can_blog, default: false
      t.boolean :can_comment, default: true
      t.timestamps
    end
  end
end