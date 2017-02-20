class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  require 'json'
  def facebook
    @conversation_id = $conversation_id
    $conversation_id = nil
    # You need to implement the method below in your model (e.g. app/models/user.rb
    @existingUser = User.find_by(uid: request.env["omniauth.auth"].uid).freeze
    @user = User.from_omniauth(request.env["omniauth.auth"], @conversation_id)
    $facebookArray = request.env["omniauth.auth"]
    if @existingUser.nil? && @conversation_id.nil?
      redirect_to pages_talk_to_christopher_path
    else
      if @user.conversation_id == nil || @user.conversation_id.blank?
        @theU = User.find_by(id: @user.id)
        @theU.destroy
        @user.destroy
      end

      if @user.persisted?
        sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
        #@user.update(conversation_id: $conversation_id) if @existingUser.conversation_id.nil? || $conversation_id.nil?
        set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
      else
        redirect_to pages_talk_to_christopher_path
      end
    end
  end

  def failure
    redirect_to root_path
  end
end
