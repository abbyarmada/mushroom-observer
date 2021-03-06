# encoding: utf-8
# TODO: move this into a new EmailController
class ObserverController
  def email_features # :root: :norobots:
    if in_admin_mode?
      @users = User.where("email_general_feature=1 && verified is not null")
      if request.method == "POST"
        @users.each do |user|
          QueuedEmail::Feature.create_email(user,
                                            params[:feature_email][:content])
        end
        flash_notice(:send_feature_email_success.t)
        redirect_to(action: "users_by_name")
      end
    else
      flash_error(:permission_denied.t)
      redirect_to(action: "list_rss_logs")
    end
  end

  def ask_webmaster_question # :nologin: :norobots:
    @email = params[:user][:email] if params[:user]
    @content = params[:question][:content] if params[:question]
    @email_error = false
    if request.method != "POST"
      @email = @user.email if @user
    elsif @email.blank? || @email.index("@").nil?
      flash_error(:runtime_ask_webmaster_need_address.t)
      @email_error = true
    elsif /http:/ =~ @content || /<[\/a-zA-Z]+>/ =~ @content
      flash_error(:runtime_ask_webmaster_antispam.t)
    elsif @content.blank?
      flash_error(:runtime_ask_webmaster_need_content.t)
    else
      WebmasterEmail.build(@email, @content).deliver_now
      flash_notice(:runtime_ask_webmaster_success.t)
      redirect_to(action: "list_rss_logs")
    end
  end

  def ask_user_question # :norobots:
    return unless (@target = find_or_goto_index(User, params[:id].to_s)) &&
                  email_question(@user) &&
                  request.method == "POST"
    subject = params[:email][:subject]
    content = params[:email][:content]
    UserEmail.build(@user, @target, subject, content).deliver_now
    flash_notice(:runtime_ask_user_question_success.t)
    redirect_to(action: "show_user", id: @target.id)
  end

  def ask_observation_question # :norobots:
    @observation = find_or_goto_index(Observation, params[:id].to_s)
    return unless @observation &&
                  email_question(@observation) &&
                  request.method == "POST"
    question = params[:question][:content]
    ObservationEmail.build(@user, @observation, question).deliver_now
    flash_notice(:runtime_ask_observation_question_success.t)
    redirect_with_query(action: "show_observation", id: @observation.id)
  end

  def commercial_inquiry # :norobots:
    return unless (@image = find_or_goto_index(Image, params[:id].to_s)) &&
                  email_question(@image, :email_general_commercial) &&
                  request.method == "POST"
    commercial_inquiry = params[:commercial_inquiry][:content]
    CommercialEmail.build(@user, @image, commercial_inquiry).deliver_now
    flash_notice(:runtime_commercial_inquiry_success.t)
    redirect_with_query(controller: "image", action: "show_image",
                        id: @image.id)
  end

  def email_question(target, method = :email_general_question)
    result = false
    user = target.is_a?(User) ? target : target.user
    if user.send(method)
      result = true
    else
      flash_error(:permission_denied.t)
      redirect_with_query(controller: target.show_controller,
                          action: target.show_action, id: target.id)
    end
    result
  end
end
