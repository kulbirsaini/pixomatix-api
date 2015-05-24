FactoryGirl.define do
  factory :user, class: User do |u|
    u.name "Kulbir Saini"
    u.email "user@example.com"
    u.password "12345678"
    u.password_confirmation { |u| u.password }
    u.confirmed_at { 10.days.ago }
    u.locked_at nil

    factory :user_with_reset_password_token do |u|
      u.reset_password_token { |u| u.password }
    end

    factory :user_without_reset_password_token do |u|
      u.reset_password_token nil
    end

    factory :locked_user do |u|
      u.email "locked@example.com"
      u.locked_at { 10.days.ago }

      factory :locked_user_with_unlock_token do |u|
        u.unlock_token { User.generate_token }
      end

      factory :locked_user_without_unlock_token do |u|
        u.unlock_token nil
      end
    end

    factory :unlocked_user do |u|
      u.email 'unlocked@example.com'
    end

    factory :confirmed_user do |u|
      u.email 'confirmed@example.com'
    end

    factory :unconfirmed_user do |u|
      u.email 'unconfirmed@example.com'
      u.confirmed_at nil

      factory :unconfirmed_user_with_confirmation_token do |u|
        u.confirmation_token { User.generate_token }
      end

      factory :unconfirmed_user_without_confirmation_token do |u|
        u.confirmation_token nil
      end
    end
  end
end
