require 'helper'

class Car
  def race_car?
    false
  end

  def rocket?(boost = 100)
    false if boost < 10
  end

  def submarine?
    fail RuntimeError
  end

  include Transitions

  state_machine initial: :parked do
    state :parked
    state :engine_started
    state :airborne
    state :under_water

    event :start do
      transitions from: :parked, to: :engine_started, guard: :race_car?
    end

    event :lift_of do
      transitions from: :parked, to: :airborne, guard: :rocket?
    end

    event :submerge do
      transitions from: :parked, to: :under_water, guard: :submarine?
    end
  end
end

class StateMachineChecksTest < Test::Unit::TestCase
  test 'raises GuardFailure when guard returns false' do
    subject = Car.new
    assert_raise Transitions::GuardFailure do
      subject.start!
    end
  end

  test 'raises when guard fails with a proper message' do
    subject = Car.new
    expected_error_message = 'Transitions: Transition for instance of `Car` from `parked` to'\
      ' `airborne` failed because the guard `rocket?` failed with arguments `[5]`'
    exception = assert_raise do
      subject.lift_of!(5)
    end
    assert_match expected_error_message, exception.message
  end

  test 'wraps exceptions from guard failures in GuardFailure' do
    subject = Car.new
    assert_raise Transitions::GuardFailure do
      subject.submerge!
    end
  end
end
