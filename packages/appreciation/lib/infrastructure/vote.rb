class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :queue_entry

  validates :direction, inclusion: { in: Appreciation::Ballot::DIRECTIONS }
end
