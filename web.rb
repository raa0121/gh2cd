require 'bundler'
Bundler.require
require 'openssl'
require 'json'

class Gh2Cd < Sinatra::Base
  def initialize *args
    Dotenv.load
    @codedeploy = Aws::CodeDeploy::Client.new(region: ENV['AWS_CODEDEPLOY_REGION'])
    super
  end

  def verify_signature(payload_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GITHUB_WEBHOOK_SEACRET'], payload_body)
    return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end

  get '/' do
    'hi'
  end

  post '/' do
    request.body.rewind
    payload_body = request.body.read
    verify_signature(payload_body)
    payload = JSON.parse params[:payload], symbolize_names: true
    if 'push' == request.env['HTTP_X_GITHUB_EVENT'] && 'refs/heads/master' == payload[:ref]
      commit_id = payload[:after]
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
