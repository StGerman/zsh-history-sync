#!/usr/local/bin/ruby -w

require 'octokit'
require 'octopoller'
require 'pry'
require 'fileutils'

stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.response :logger
  builder.adapter Faraday.default_adapter
end

Octokit.middleware = stack


class ZshHistory
  DESCRIPTION = 'zsh-history'.freeze

  attr_reader :access_token, :gist_id, :file_path, :client

  def call(access_token: ENV.fetch('GITHUB_TOKEN'), gist_id: ENV.fetch('GIST_ID'), file_path: ENV.fetch('HISTFILE'))
    @access_token, @gist_id, @file_path = access_token, gist_id, file_path
    @client = Octokit::Client.new(access_token: access_token)

    if first_run?
      result = client.create_gist(payload)
      new_gist_id = result['id']
      puts "you should add to ~/.zshrc 'export GIST_ID=#{new_gist_id}'"
    else
      result = client.edit_gist(gist_id, payload)
    end
  end

  private

  def first_run?
    client.gists.empty? { |g| g[:id] == gist_id }
  end

  def history_content
    File.read(file_path).force_encoding("ISO-8859-1").encode("UTF-8")
  end

  def payload
    @payload ||= {
      description: DESCRIPTION,
      files: {
        history: { content: history_content }
      }
    }
  end
end

ZshHistory.new.call
