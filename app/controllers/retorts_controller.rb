class DiscourseRetort::RetortsController < ::ApplicationController
  requires_plugin DiscourseRetort::PLUGIN_NAME
  before_action :verify_post_and_user, only: :update

  def update
    params.require(:retort)
    if Emoji.exists?(params[:retort])
      retort ||= Retort.toggle_user(post.id, current_user.id, params[:retort])
      if retort && retort.valid?
        MessageBus.publish "/retort/topics/#{params[:topic_id] || post.topic_id}", serialized_post_retorts
        render json: { success: :ok }
      else
        respond_with_unprocessable("Unable to save that retort. Please try again")
      end
    else
      respond_with_unprocessable("Bad Argument")
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
