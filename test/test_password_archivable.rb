require 'test_helper'

class TestPasswordArchivable < ActiveSupport::TestCase
  setup do
    Devise.password_archiving_count = 2
  end

  teardown do
    Devise.password_archiving_count = 1
  end

  def set_password(user, password)
    user.password = password
    user.password_confirmation = password
    user.save!
  end

  test 'cannot use same password' do
    user = User.create email: 'bob@microsoft.com', password: 'Password1', password_confirmation: 'Password1'
    assert_raises(ActiveRecord::RecordInvalid) { set_password(user,  'Password1') }
  end

  test 'cannot use archived passwords' do
    assert_equal 2, Devise.password_archiving_count

    user = User.create email: 'bob@microsoft.com', password: 'Password1', password_confirmation: 'Password1'
    assert_equal 0, OldPassword.count

    set_password(user,  'Password2')
    assert_equal 1, OldPassword.count

    assert_raises(ActiveRecord::RecordInvalid) { set_password(user,  'Password1') }

    set_password(user,  'Password3')
    assert_equal 2, OldPassword.count

    # rotate first password out of archive
    assert set_password(user,  'Password4')

    # archive count was 2, so first password should work again
    assert set_password(user,  'Password1')
    assert set_password(user,  'Password2')
  end

  test 'the option should be dynamic during runtime' do
    class ::User
      def archive_count
        1
      end
    end

    user = User.create email: 'bob@microsoft.com', password: 'Password1', password_confirmation: 'Password1'

    assert set_password(user,  'Password2')

    assert_raises(ActiveRecord::RecordInvalid) { set_password(user,  'Password2') }

    assert_raises(ActiveRecord::RecordInvalid) { set_password(user,  'Password1') }
  end
end
