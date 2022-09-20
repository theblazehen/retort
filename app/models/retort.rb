require_dependency 'rate_limiter'

class Retort < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  validates :emoji, presence: true
  validates_associated :post, :user, presence: true

  def toggle(actor_id)
    if self.deleted_at
      self.deleted_at = nil
      self.deleted_by = nil
    else
      self.deleted_at = Time.now
      self.deleted_by = actor_id
    end
    self.save!
  end

  def self.remove_retort(post_id, emoji, actor_id)
    exist_record = Retort.where(post_id: post_id, emoji: emoji)
    if exist_record
      exist_record.update_all(deleted_at: Time.now, deleted_by: actor_id)
      return true
    end
    return false
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
