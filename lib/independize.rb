require 'independize/railtie'

module Independize
end
class IndependizeController < ActionController::Base
  def sample_action
    render
  end
end
