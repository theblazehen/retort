class ChangeUsernameToId < ActiveRecord::Migration[7.0]
  def change
    details = PostDetail.where(extra: "retort")
    details.each do |detail|
      emoji = detail.key.split("|").first
      if !Emoji.exists?(emoji)
        detail.destroy
        next
      end
      usernames = JSON.parse(detail.value)
      ids = User.where(username: usernames).ids
      detail.value = ids
      detail.save!
    end

    empty_details = PostDetail.where(extra: "retort", value: "[]")
    empty_details.destroy_all
  end
end
