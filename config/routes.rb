Rails.application.routes.draw do
  resources :home, only: [:index]
  root 'home#index'

  namespace :api, defaults: { format: :json } do
    scope module: :v1, constraints: Pixomatix::ApiConstraints.new(version: 1, default: true) do

      resources :auth, controller: :auth, only: [] do
        collection do
          post :register
          post :login
          get :user
          get :validate
          delete :logout

          get :reset_password, action: :reset_password_instructions, as: :reset_password_instructions
          post :reset_password

          get :unlock, action: :unlock_instructions, as: :unlock_instructions
          post :unlock

          get :confirm, action: :confirmation_instructions, as: :confirmation_instructions
          post :confirm
        end
      end

      resources :users, only: [] do
        collection do
          put :update
          patch :update
          delete :destroy, as: :cancel
        end
      end

      resources :images, only: [:index, :show]  do
        member do
          get :original
          get :download
          get :galleries
          get :images
          get :image
          get :parent
        end
      end
    end
  end
end
