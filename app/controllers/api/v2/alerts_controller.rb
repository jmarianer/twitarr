class API::V2::AlertsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :login_required, only:[:check]


  def login_required
    head :unauthorized unless logged_in? || valid_key?(params[:key])
  end

  def index
    announcements = Announcement.valid_announcements.map { |x| x.decorate.to_hash }
    if logged_in? || valid_key?(params[:key])
      last_checked_time = current_user[:last_viewed_alerts]
      tweet_mentions = StreamPost.view_mentions(query: current_username,
                                                mentions_only: true).map {|p| p.decorate.to_hash(current_username, params) }
      forum_mentions = Forum.view_mentions(query: current_username,
                                                mentions_only: true).map {|p| p.decorate.to_meta_hash }
      unread_seamail = current_user.seamails(unread: true).map{|m| m.decorate.to_meta_hash }

      unless params[:no_reset]
        current_user.reset_last_viewed_alerts
        current_user.save!
      end
    else
      last_checked_time = session[:last_viewed_alerts] || Time.at(0).to_datetime
      tweet_mentions = []
      forum_mentions = []
      unread_seamail = []
      session[:last_viewed_alerts] = DateTime.now unless params[:no_reset]
    end
    render_json tweet_mentions: tweet_mentions, forum_mentions: forum_mentions,
                announcements: announcements, unread_seamail: unread_seamail, last_checked_time: (last_checked_time.to_f * 1000).to_i
  end

  def check
    render_json status: 'ok', user: current_user.decorate.alerts_meta
  end
end
