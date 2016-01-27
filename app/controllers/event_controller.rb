class EventController < ApplicationController

  def page
    per_page = 20
    offset = params[:page].to_i || 0

    events = Event.where(:start_time.gte => DateTime.now).offset(offset * per_page).limit(per_page).order_by(:start_time.asc)
    next_page = offset + 1
    next_page = nil if Event.where(:start_time.gte => DateTime.now).offset((offset + 1) * per_page).limit(per_page).order_by(:start_time.asc).to_a.count ==  0
    prev_page = offset - 1
    prev_page = nil if prev_page < 0

    render_json events: events.map { |x| x.decorate.to_hash(current_username)}, next_page: next_page, prev_page: prev_page
  end

  def past_events
    events = Event.where(:start_time.lt => DateTime.now).limit(20).order_by(:start_time.desc)
    render_json events: events.map { |x| x.decorate.to_hash(current_username)}
  end

  def upcoming
    # Shows all upcoming events for the user, starting from one hour ago up to 3 hours from now and removes events that have had their end_time past 
    events = Event.where(:start_time.gte => (DateTime.now - 1.hours)).where(:start_time.lte => (DateTime.now + 3.hours)).limit(20).order_by(:start_time.desc)
    events = events.map {|x| x if !x.end_time or x.end_time > DateTime.now }.compact
    events = events.map { |x| x if x.signups.include? current_username or x.favorites.include? current_username }.compact
    render_json events: events.map { |x| x.decorate.to_hash(current_username)}
  end
end