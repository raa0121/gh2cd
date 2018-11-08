require 'bundler'
Bundler.require
require 'json'

class Gh2Cd < Sinatra::Base
  def initialize *args
    Dotenv.load
    @codedeploy = Aws::CodeDeploy::Client.new(region: ENV['AWS_CODEDEPLOY_REGION'])
    super
  end

  get '/' do
    'hi'
  end

  post '/' do
    payload = JSON.parse params[:payload], symbolize_names: true
    if false === params[:key].empty? &&
       params['X-Hub-Signature'] == ENV['GITHUB_WEBHOOK_SEACRET'] &&
       'push' == params['X-GitHub-Event'] &&
       'refs/heads/master' == payload[:ref]
      commit_id = payload[:head]
      data = {
        application_name: ENV['AWS_CODEDEPLOY_APPLICATION_NAME'],
        deployment_group_name: ENV['AWS_CODEDEPLOY_DEPLOYMENT_GROUP_NAME'],
        revision: {
          revision_type: "GitHub",
          git_hub_location: {
            repository: payload[:repository][:full_name],
            commit_id: commit_id
          }
        }
      }
      deployment_id = @codedeploy.create_deployment(data)
      deployment_id.to_s
    end
  end
end
