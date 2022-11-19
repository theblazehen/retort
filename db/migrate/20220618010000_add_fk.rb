# frozen_string_literal: true
class AddFk < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :retorts, :posts
    add_foreign_key :retorts, :users
  end
end
