require 'sinatra'
require 'json'

get '/' do
  'Hello world!'
end

get '/seed' do
    start = params['start'] || 0
    stop = params['stop'] || 1
    r = Range.new(start.to_i, stop.to_i)

    content_type :json
    { result: rand(r) }.to_json
end

get '/livesz' do
    halt 200
end

get '/readyz' do
    halt 200
end