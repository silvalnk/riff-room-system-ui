class QueueEntry < ApplicationRecord
  belongs_to :room
  belongs_to :user

  scope :waiting, -> { where(status: "waiting").order(:position) }
end
