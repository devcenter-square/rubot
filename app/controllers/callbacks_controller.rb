class CallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @admin = Admin.from_omniauth(request.env["omniauth.auth"])
    if @admin.email != ""
      sign_in_and_redirect @admin
    else
      # this will probable never get thrown now. todo: limit sign-in to DC admins?
      puts "Auth ERROR!!!"
      redirect_to new_admin_session_path, flash: {error: 'You probably are not an admin of the DC community... :stuck_out_tongue:' }
    end
  end
end