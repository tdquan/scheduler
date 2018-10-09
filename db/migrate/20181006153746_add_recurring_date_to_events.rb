class AddRecurringDateToEvents < ActiveRecord::Migration[5.0]
  def change
  	add_column :events, :recurring_date, :int
  end
end
