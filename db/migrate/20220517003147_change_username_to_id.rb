class ChangeUsernameToId < ActiveRecord::Migration[7.0]
  def change
    details = PostDetail.where(extra: "retort")
    details.each do |detail|
      usernames = JSON.parse(detail.value)
      ids = usernames.map { |username| User.find_by(username: username) }.reject { |user| user.nil? }.map { |user| user.id }
      detail.value = ids
      detail.save!
    end

    empty_details = PostDetail.where(extra: "retort", value: "[]")
    empty_details.destroy_all
  end
end
