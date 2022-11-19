# frozen_string_literal: true
class SoftDeleteRetort < ActiveRecord::Migration[7.0]
  def change
    add_column :retorts, :deleted_at, :datetime, null: true
    add_column :retorts, :deleted_by, :integer, null: true
  end
end
