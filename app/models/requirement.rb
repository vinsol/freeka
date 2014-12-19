class Requirement < ActiveRecord::Base
  include AASM

  enum status: { pending: 0, in_process: 1, fulfilled: 2 }

  # Association
  has_one :image, -> { where(attacheable_sub_type: :Image) }, as: :attacheable, class_name: :Attachment, dependent: :destroy
  has_many :files, -> { where(attacheable_sub_type: :File) }, as: :attacheable, class_name: :Attachment, dependent: :destroy
  belongs_to :address, foreign_key: :location_id, dependent: :destroy
  belongs_to :person, foreign_key: :requestor_id
  has_many :category_requirements, dependent: :destroy
  has_many :categories, through: :category_requirements
  has_many :donor_requirements, dependent: :destroy
  has_many :interested_donors, through: :donor_requirements, source: :user
  has_many :comments, dependent: :destroy

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :files, allow_destroy: true
  accepts_nested_attributes_for :image, allow_destroy: true

  # Validation
  validates :title, presence: true
  validate :date_not_in_past, unless: :status_changed?

  # Callbacks
  before_destroy :prevent_if_not_pending

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :with_category, ->(category_id) { Category.find_by(id: category_id).requirements }
  scope :with_status_not, ->(status) { where.not(status: status) }
  scope :with_status, ->(status) { where(status: status) }
  scope :live, -> { where('expiration_date >= ?', Date.today)}

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :in_process
    state :fulfilled

    event :process do
      transitions from: :pending, to: :in_process
    end

    event :unprocess do
      transitions from: :in_process, to: :pending
    end

    event :fulfill do
      after do
        comments.create(content: 'Requirement has been fulfilled. Thank You all.', user_id: requestor_id)
        thank_users
      end
      transitions from: :in_process, to: :fulfilled
      transitions from: :pending, to: :fulfilled
    end
  end

  def donor_requirement(user_id)
    donor_requirements.find { |dr| dr.donor_id == user_id }
  end

  def donor
    donor_requirements.find(&:donated?).try(:user)
  end

  def reject_current_donor
    donor_requirements.find(&:current?).reject!
  end

  def update_donors
    if donor = donor_requirements.sort_by(&:created_at).find(&:interested?)
      donor.make_current!
    else
      unprocess!
    end
  end

  def donate
    donor_requirements.find(&:current?).donate!
  end

  def update_donor_and_reject_interested_donors
    donor_requirements.each do |donor_requirement|
      if donor_requirement.interested?
        donor_requirement.reject!
      elsif donor_requirement.current?
        donor_requirement.donate!
      end
    end
  end

  private

    def thank_users
      donor_requirements.interested.includes(:user).each do |donor_requirement|
        DonorMailer.thank_interested_donor(donor_requirement.user, self).deliver
      end
      donor_requirements.donated.includes(:user).each do |donor_requirement|
        DonorMailer.thank_fulfilling_donor(donor_requirement.user, self).deliver
      end
    end

    def date_not_in_past
      errors.add(:expiration_date, 'cannot be a past date') if expiration_date < Date.today
    end
  
    def prevent_if_not_pending
      if !pending?
        errors.add(:status, 'Cannot be destroyed or updated in -in process- or -fulfilled- state')
        false
      end
    end

end
