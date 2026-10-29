require "date"
require "hub_kernel-interface"
require "hub_kernel/api/version"
require "hub_kernel/api/major_version"
require "hub_kernel/api/description"
require "hub_kernel/api/description_files"
require "hub_kernel/api/engine"

module HubKernel
  module Api
    UnservableHubError = HubKernel::Interface::UnservableHubError
    class UnservedMajorError < StandardError; end
    class RetiredMajorError < StandardError; end

    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method
    mattr_accessor :versions, default: []

    def self.hubs = HubKernel::Interface.hubs

    def self.hubs=(hubs)
      HubKernel::Interface.hubs = hubs
    end

    def self.find(name) = HubKernel::Interface.find(name)

    def self.check!
      problems = served_list_problems + version_problems
      raise UnservableHubError, problems.join("\n") if problems.any?
    end

    def self.version_problems
      return [] if versions.empty?

      unlisted_earlier_answers + newest_earlier_answers + unformed_versions + doubled_majors + undated(:deprecated_on, "it was deprecated") + undated(:sunset, "it stops being served") +
        non_dates(:deprecated_on) + non_dates(:sunset) + all_retired
    end

    def self.served_list_problems
      HubKernel::Interface.check!
      []
    rescue UnservableHubError => error
      error.message.split("\n")
    end

    def self.unlisted_earlier_answers
      earlier_answers.reject { |_hub, _exposure, earlier| formed_versions.map(&:major).include?(earlier.major) }.map do |hub, exposure, earlier|
        "#{hub.name} declares an earlier answer to #{exposure.name} for major #{earlier.major}, which the host does not list"
      end
    end

    def self.newest_earlier_answers
      earlier_answers.select { |_hub, _exposure, earlier| earlier.major == formed_versions.map(&:major).max }.map do |hub, exposure, earlier|
        "#{hub.name} declares an earlier answer to #{exposure.name} for major #{earlier.major}, the newest major, which has no newer answer to translate from"
      end
    end

    def self.unformed_versions
      (versions - formed_versions).map { |listed| "The listed version #{listed.version} is not in major.minor.patch form" }
    end

    def self.formed_versions = versions.select { |listed| listed.version.to_s.match?(/\A\d+\.\d+\.\d+\z/) }

    def self.doubled_majors
      formed_versions.group_by(&:major).select { |_major, listed| listed.size > 1 }.keys.map { |major| "Major #{major} is listed more than once" }
    end

    def self.undated(field, meaning)
      formed_versions.select { |listed| listed.deprecated? && listed.public_send(field).nil? }.map { |listed| "Major #{listed.major} is deprecated with no #{field}: date #{meaning}" }
    end

    def self.all_retired
      return [] unless versions.all?(&:retired?)

      [ "Every listed major is retired, so a call with no Accept-Version has no major to be answered at" ]
    end

    def self.non_dates(field)
      formed_versions.reject { |listed| listed.public_send(field).nil? || listed.public_send(field).is_a?(Date) }.map do |listed|
        "Major #{listed.major} gives #{field}: as #{listed.public_send(field).inspect}, which is not a Date"
      end
    end

    def self.earlier_answers
      exposing_hubs.flat_map { |hub| hub.exposures.flat_map { |exposure| exposure.earlier_answers.map { |earlier| [ hub, exposure, earlier ] } } }
    end

    def self.exposing_hubs = HubKernel::Interface.served.values.uniq.select { |hub| hub.respond_to?(:exposures) }
    private_class_method :served_list_problems, :version_problems, :unlisted_earlier_answers, :newest_earlier_answers, :unformed_versions, :formed_versions, :doubled_majors, :undated, :all_retired, :non_dates, :earlier_answers, :exposing_hubs
  end
end
