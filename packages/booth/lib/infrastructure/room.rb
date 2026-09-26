class Room < ApplicationRecord
  belongs_to :dj, class_name: "User", optional: true
  has_many :queue_entries, dependent: :destroy
  has_many :keypresses, dependent: :destroy
  has_many :outbox_messages, dependent: :destroy

  def to_param
    slug
  end

  def self.catalog
    where(slug: [ nil, "" ]).find_each do |room|
      room.update!(slug: "sala-#{room.id}", name: room.name.presence || "Sala")
    end
    [
      [ "Neon Floor", "neon-floor", "Pista neon para house e vocal." ],
      [ "After Hours", "after-hours", "Madrugada lenta, luz baixa." ],
      [ "Rooftop", "rooftop", "Fim de tarde no terraço." ],
      [ "Basement", "basement", "Grave no subsolo." ]
    ].each do |name, slug, blurb|
      find_or_create_by!(slug: slug) { |room| room.name = name; room.blurb = blurb }
    end
    order(:name)
  end

  def playing?
    phase == "playing"
  end
end
