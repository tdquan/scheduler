class Event < ApplicationRecord
	after_create :validate_recurring_event
	validates :starts_at, :ends_at, presence: true

	Agenda = Struct.new(:date, :slots, :substitution)

	def self.availabilities(time)
		@agendas = []
		7.times do
			slots = []
			booked = []
			single_events = Event.where("starts_at >= ? AND starts_at <= ? AND weekly_recurring IS ? AND kind IS ?", time.beginning_of_day, time.end_of_day, false, "opening")
			recurring_events = Event.where("weekly_recurring IS ? AND recurring_date = ?", true, time.wday)
			single_appointments = Event.where("starts_at >= ? AND starts_at <= ? AND weekly_recurring IS ? AND kind IS ?", time.beginning_of_day, time.end_of_day, false, "appointment")
			recurring_appointments = Event.where("weekly_recurring IS ? AND recurring_date = ? AND kind IS ?", true, time.wday, "appointment")
			date = Date.parse(time.to_s)

			single_events.each do |event|
				time_slot = event.starts_at
				while time_slot < event.ends_at
					slots << time_slot.strftime("%H:%M")
					time_slot += 30.minutes
				end
			end

			recurring_events.each do |event|
				time_slot = event.starts_at
				while time_slot < event.ends_at
					slots << time_slot.strftime("%H:%M")
					time_slot += 30.minutes
				end
			end

			single_appointments.each do |app|
				time_slot = app.starts_at
				while time_slot < app.ends_at
					booked << time_slot.strftime("%H:%M")
					time_slot += 30.minutes
				end
			end

			recurring_appointments.each do |event|
				time_slot = event.starts_at
				while time_slot < event.ends_at
					booked << time_slot.strftime("%H:%M")
					time_slot += 30.minutes
				end
			end

			booked.each do |booked_slot|
				tslot = slots.index(booked_slot)
				slots.slice!(tslot) unless tslot.nil?
			end

			slots = slots.sort.map { |slot| Time.parse(slot).strftime("%-k:%M") }

			@agendas << Agenda.new(date, slots, nil)
			time += 1.day
		end
		return @agendas
	end

	private

	def validate_recurring_event
		if self.weekly_recurring
			self.update(recurring_date: self.starts_at.wday)
		else
			self.update(recurring_date: nil)
		end
	end
end
