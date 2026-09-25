class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :open_rounds

  before_action { Current.user = current_user }

  private

  # Running rounds of the user's groups that the user has not finished yet.
  # The banner stays until this player has played the round (or the round is over).
  def open_rounds
    return Round.none unless logged_in?
    done = Participation.where(user_id: current_user.id, finished: true).select(:round_id)
    @open_rounds ||= Round.active.where(group_id: current_user.group_ids).where.not(id: done)
                          .includes(:group).order(:started_at).to_a
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  rescue_from Pundit::NotAuthorizedError do
    redirect_back_or_to dashboard_path, alert: "Dazu hast du keine Berechtigung."
  end

  rescue_from ActiveRecord::StaleObjectError do
    redirect_back_or_to dashboard_path, alert: "Jemand hat gleichzeitig etwas geändert. Bitte versuche es nochmal."
  end

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def require_login
    redirect_to new_session_path, alert: "Bitte melde dich zuerst an." unless logged_in?
  end
end
