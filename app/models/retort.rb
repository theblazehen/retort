require_dependency 'rate_limiter'

class Retort < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  validates :emoji, presence: true
  validates_associated :post, :user, presence: true

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
