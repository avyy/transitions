module Transitions
  # Custom exception for guard failures on transition.
  class GuardFailure < RuntimeError; end
  # Custom exception for unknown guard types (everything except for Symbol, String or Proc)
  class UnknownGuardType < RuntimeError; end

  # Represent a `state transition`. Mostly used by the `Event` model.
  class StateTransition
    attr_reader :from, :to, :guards, :on_transition
    # TODO: `from` and `to` should be private as well
    private :guards, :on_transition

    def initialize(opts)
      @from = opts[:from]
      @to = opts[:to]
      @guards = opts[:guard]
      @on_transition = opts[:on_transition]
    end

    #
    # @param obj [Any] - the subject
    # @param args [Array<Symbol>] - any arguments passed into the transition method
    #   E.g. something like
    #     car.drive!(:fast, :now)
    #   with `car` being the subject and `drive` the transition method would result
    #   in `args` looking like this:
    #     [:fast, :now]
    #
    # @return [Bool]
    #
    def executable?(obj, *args)
      [@guards].flatten.all? { |g| perform_guard(obj, g, *args) }
    end

    #
    # @param obj [Any] - the subject
    # @param args [Array<Symbol>] - any arguments passed into the transition method
    #   E.g. something like
    #     car.drive!(:fast, :now)
    #   with `car` being the subject and `drive` the transition method would result
    #   in `args` looking like this:
    #     [:fast, :now]
    #
    # @return [void]
    #
    def execute(obj, *args)
      case @on_transition
      when Symbol, String
        obj.send(@on_transition, *args)
      when Proc
        @on_transition.call(obj, *args)
      when Array
        @on_transition.each do |callback|
          obj.send(callback, *args)
        end
      else
        # TODO: We probably should check for this in the constructor and not that late.
        fail ArgumentError, "You can only pass a Symbol, a String, a Proc or an Array to 'on_transition' - got #{@on_transition.class}." unless @on_transition.nil?
      end
    end

    def perform_guards!(obj, *args)
      [@guards].flatten.each do |g|
        result = perform_guard(obj, g, *args) rescue false
        fail GuardFailure,
             guard_failure_message(obj, g, *args) unless result
      end
    end

    def ==(obj)
      @from == obj.from && @to == obj.to
    end

    def from?(value)
      @from == value
    end

    private

    def perform_guard(obj, guard, *args)
      if guard.respond_to?(:call)
        guard.call(obj, *args)
      elsif guard.is_a?(Symbol) || guard.is_a?(String)
        obj.send(guard, *args)
      else
        true
      end
    end

    def guard_failure_message(obj, guard, *args)
      ''.tap do |message|
        message << "Transitions: Transition for instance of `#{obj.class.name}` from "\
        "`#{from}` to `#{to}` failed because the guard `#{guard}` failed"
        message << " with arguments `#{args.inspect}`" if args.size > 0
      end
    end
  end
end
