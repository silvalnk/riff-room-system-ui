class OutboxMessage < ApplicationRecord
  belongs_to :room

  scope :unpublished, -> { where(published_at: nil).order(:id) }
end
