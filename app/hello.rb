require 'sinatra'
require 'vite_ruby'
require_relative './helper'

set :public_folder, -> { File.join(root, '../public') }

get '/' do
  erb 'Hello, World from Web'
end
