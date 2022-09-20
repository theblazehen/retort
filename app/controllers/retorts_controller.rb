class DiscourseRetort::RetortsController < ::ApplicationController
  requires_plugin DiscourseRetort::PLUGIN_NAME
  before_action :verify_post_and_user, only: :update
  before_action :verify_post_and_user, only: :delete

  def update
    params.require(:retort)
    emoji = params[:retort]
    if !Emoji.exists?(emoji)
      respond_with_unprocessable("Bad Argument")
      return
    end
    
    disabled_emojis = SiteSetting.retort_disabled_emojis.split("|")
    if disabled_emojis.include?(emoji)
      respond_with_unprocessable("Unable to save that retort.")
      return
    end

    exist_record = Retort.find_by(post_id: post.id, user_id: current_user.id, emoji: emoji)
    if exist_record
      if (!(current_user.staff? || current_user.trust_level == 4)) && 
        exist_record.updated_at < SiteSetting.retort_withdraw_tolerance.second.ago
        respond_with_unprocessable("Exceed max withdraw time limit.")
        return
      end
      exist_record.toggle(current_user.id)
    else
      exist_record = Retort.create(post_id: post.id, user_id: current_user.id, emoji: emoji)
    end

    MessageBus.publish "/retort/topics/#{params[:topic_id] || post.topic_id}", serialized_post_retorts
    render json: { success: :ok }
 
  end

  def remove
    params.require(:retort)
    if current_user.staff?
      retort ||= Retort.remove_retort(post.id, params[:retort])
      if retort
        UserHistory.create!(
          acting_user_id: current_user.id,
          action: UserHistory.actions[:post_edit],
          post_id: post.id,
          details: "remove retort :#{params[:retort]}:"
        )
        MessageBus.publish "/retort/topics/#{params[:topic_id] || post.topic_id}", serialized_post_retorts
        render json: { success: :ok }
      end
    else
      respond_with_unprocessable("Unable to remove that retort.")
    end
  end

    private

  def post
    @post ||= Post.find_by(id: params[:post_id]) if params[:post_id]
  end

  def verify_post_and_user
    respond_with_unprocessable("Unable to find post #{params[:post_id]}") unless post
    respond_with_unprocessable("You are not permitted to modify this") unless current_user && !current_user.silenced?
  end

  def serialized_post_retorts
    ::PostSerializer.new(post.reload, scope: Guardian.new, root: false).as_json
  end

  def respond_with_unprocessable(error)
    render json: { errors: error }, status: :unprocessable_entity
  end
end
