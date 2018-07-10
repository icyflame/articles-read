class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	protected

	def configure_permitted_parameters
		devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :email, :password, :password_confirmation ])
		devise_parameter_sanitizer.permit(:sign_in, keys: [ :login, :username, :email, :password ])
		devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :email, :password, :password_confirmation, :current_password ])
	end

  def is_valid_email text
    return text =~ Devise.email_regexp
  end
end
