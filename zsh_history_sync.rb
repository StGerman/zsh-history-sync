#!/usr/local/bin/ruby -w

require 'octokit'
require 'octopoller'
require 'pry'
require 'fileutils'

def debug_mode
  stack = Faraday::RackBuilder.new do |builder|
    builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
    builder.use Octokit::Middleware::FollowRedirects
    builder.use Octokit::Response::RaiseError
    builder.use Octokit::Response::FeedParser
    builder.response :logger
    builder.adapter Faraday.default_adapter
  end

  Octokit.middleware = stack
end

debug_mode if ENV['DEBUG']

class ZshHistory
  DESCRIPTION = 'zsh-history'.freeze

  attr_reader :access_token, :gist_id, :file_path, :client

  def initialize(access_token: ENV.fetch('GITHUB_TOKEN'), gist_id: ENV.fetch('GIST_ID'), file_path: ENV.fetch('HISTFILE'))
    @access_token, @gist_id, @file_path = access_token, gist_id, file_path
    @client = Octokit::Client.new(access_token: access_token)
  end

  def call
    puts 'start push'
    binding.pry
    client.edit_gist(gist_id, payload)
    puts 'finish push'

    result = client.gist(gist_id)
    history = result.dig(:files, :history, :content)
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
