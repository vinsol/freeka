class WelcomeController < ApplicationController

  def index
    if current_admin
      redirect_to admins_welcome_index_path
    else
      #TODO: What is `2`? Do not use hardcoded values anywhere.
      @requirements = Requirement.enabled.with_status_not(2).includes(:address, :donor_requirements, :categories, :interested_donors).order(:expiration_date).page params[:page]
      load_donations
      render 'requirements/index'
    end
  end

end