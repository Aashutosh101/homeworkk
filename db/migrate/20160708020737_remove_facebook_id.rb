class RemoveFacebookId < ActiveRecord::Migration
  def change
  	remove_column :users, :fb_id
  end
end
