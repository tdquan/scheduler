class Event < ApplicationRecord
	scope :next_week, ->(time) { where("(starts_at >= ? AND starts_at <= ?) OR (weekly_recurring IS ?)", time.beginning_of_day, (time + 6.days).end_of_day, true) }
	after_create :validate_recurring_event
	validates :starts_at, :ends_at, presence: true

	Agenda = Struct.new(:date, :slots, :substitution)

	def self.availabilities(time)
		@agendas = []
		next_week_events = Event.next_week(time).to_a
		7.times do
			events = Event.find_event_type_for_day(next_week_events, time, "opening")
			appointments = Event.find_event_type_for_day(next_week_events, time, "appointment")
			date = Date.parse(time.to_s)

			slots = Event.convert_time(events)
			booked = Event.convert_time(appointments)

			slots = (slots.uniq - booked.uniq).sort.map { |slot| Time.parse(slot).strftime("%-k:%M") }

			@agendas << Agenda.new(date, slots, nil)
			time += 1.day
		end
		return @agendas
	end

	private

	def self.find_event_type_for_day(events, time, type)
		events.select { |event| ((event.starts_at >= time.beginning_of_day && event.starts_at <= time.end_of_day && !event.weekly_recurring && event.kind == type) || (event.weekly_recurring && event.recurring_date == time.wday && event.kind == type)) }
	end

	def self.convert_time(events)
		slots = []
		events.each do |event|
			time_slot = event.starts_at
			while time_slot < event.ends_at
				slots << time_slot.strftime("%H:%M")
				time_slot += 30.minutes
			end
		end
		return slots
	end

	def validate_recurring_event
		if self.weekly_recurring
			self.update(recurring_date: self.starts_at.wday)
		else
			self.update(recurring_date: nil)
		end
	end
end
