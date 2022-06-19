class RetortSerializer < ActiveModel::Serializer
  attributes :post_id, :usernames, :emoji

  define_method :post_id,   -> { object.first.post_id }
  define_method :emoji,     -> { object.first.emoji }
  def usernames
    ids = object.pluck(:user_id)
      ids ? User.where(id: ids).pluck(:username) : []
  end
end
