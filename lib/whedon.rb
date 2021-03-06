require 'octokit'
require 'time'

require_relative 'whedon/auditor'
require_relative 'whedon/bibtex'
require_relative 'whedon/github'
require_relative 'whedon/processor'
require_relative 'whedon/review'
require_relative 'whedon/reviews'
require_relative 'whedon/version'

require 'dotenv'
Dotenv.load

module Whedon

  AUTHOR_REGEX = /(?<=\*\*Submitting author:\*\*\s)(\S+)/
  REPO_REGEX = /(?<=\*\*Repository:\*\*.<a\shref=)"(.*?)"/
  VERSION_REGEX = /(?<=\*\*Version:\*\*\s)(\S+)/
  ARCHIVE_REGEX = /(?<=\*\*Archive:\*\*.<a\shref=)"(.*?)"/
  DOI_PREFIX = "10.21105"

  # Probably a much nicer way to do this...
  # 1 volume per year since 2016
  CURRENT_VOLUME = Time.new.year - 2015

  # 1 issue per month since May 2016
  CURRENT_ISSUE = 1 + ((Time.new.year * 12 + Time.new.month) - (Time.parse('2016-05-05').year * 12 + Time.parse('2016-05-05').month))

  class Paper
    include GitHub

    attr_accessor :review_issue_id
    attr_accessor :review_repository
    attr_accessor :review_issue_body

    def self.list
      reviews = Whedon::Reviews.new(ENV['JOSS_REVIEW_REPO']).list_current
      return "No open reviews" if reviews.nil?

      reviews.each do |issue_id, vals|
        puts "#{issue_id}: #{vals[:url]} (#{vals[:opened_at]})"
      end
     end

    def initialize(review_issue_id)
      @review_issue_id = review_issue_id
      @review_repository = ENV['JOSS_REVIEW_REPO']
    end

    def review_issue
      review = Whedon::Review.new(review_issue_id, review_repository)
      @review_issue_body = review.issue_body
      return review
    end

    def audit
      review_issue if review_issue_body.nil?
      Whedon::Auditor.new(review_issue_body).audit
    end

    def download
      review_issue if review_issue_body.nil?
      Whedon::Processor.new(review_issue_id, review_issue_body).clone
    end

    def compile
      review_issue if review_issue_body.nil?
      processor = Whedon::Processor.new(review_issue_id, review_issue_body)
    end
  end
end
