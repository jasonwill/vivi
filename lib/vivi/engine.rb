module Vivi
  class Engine < Rails::Engine
    isolate_namespace Vivi
    
    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
    
    initializer 'Vivi.controller' do |app|  
      ActiveSupport.on_load(:action_controller) do  
        include Vivi::Decorator  
      end
    end
        
  end
end
