module ActionArgs
  module ActiveSupport
    module CallbackParameterizer
      if Rails.version > '4.1'
        # Extending AS::Callbacks::Callback's `make_lambda` not just to call specified
        # method but to call the method with method parameters taken from `params`.
        # This would happen only when
        # * the filter was defined in Symbol form
        # * the target object is_a ActionController object
        def make_lambda(filter)
          if Symbol === filter
            lambda do |target, _, &blk|
              if ActionController::Base === target
                target.strengthen_params! filter
                values = target.extract_method_arguments_from_params filter
                target.send filter, *values, &blk
              else
                target.send filter, &blk
              end
            end
          else
            super
          end
        end

      elsif Rails.version > '4.0'
        def apply(code)
          if (Symbol === @filter) && (@klass < ActionController::Base)
            method_body = <<-FILTER
              strengthen_params! :#{@filter}
              values = extract_method_arguments_from_params :#{@filter}
              send :#{@filter}, *values
            FILTER
            if @kind == :before
              @filter = "begin\n#{method_body}\nend"
            else
              @filter = method_body.chomp
            end
          end
          super
        end
      end
    end
  end
end

module ActiveSupport
  module Callbacks
    class Callback
      prepend ActionArgs::ActiveSupport::CallbackParameterizer
    end
  end
end
