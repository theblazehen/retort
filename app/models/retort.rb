require_dependency 'rate_limiter'

class Retort < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  validates :emoji, presence: true
  validates_associated :post, :user, presence: true

  def self.toggle_user(post_id, user_id, emoji)
    exist_record = Retort.find_by(post_id: post_id, user_id: user_id, emoji: emoji)
      if exist_record
        exist_record.destroy!
      else
        exist_record = Retort.create(post_id: post_id, user_id: user_id, emoji: emoji)
      end
      exist_record
  end

  def self.remove_retort(post_id, emoji)
    exist_record = Retort.where(post_id: post_id, emoji: emoji)
    if exist_record
      exist_record.destroy_all
    end
    exist_record
  end

  include RateLimiter::OnCreateRecord
  rate_limit :retort_rate_limiter
  def retort_rate_limiter
    @rate_limiter ||= RateLimiter.new(user, "create_retort", retort_max_per_day, 1.day.to_i)
  end

  def retort_max_per_day
    (SiteSetting.retort_max_per_day * retort_trust_multiplier).to_i
  end

  def retort_trust_multiplier
    return 1.0 unless user&.trust_level.to_i >= 2
      SiteSetting.send(:"retort_tl#{user.trust_level}_max_per_day_multiplier")
  end
end
