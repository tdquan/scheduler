class EventDefaultValues < ActiveRecord::Migration[5.0]
  def change
  	change_column_default :events, :weekly_recurring, false
  	change_column_default :events, :kind, "opening"
  end
end
