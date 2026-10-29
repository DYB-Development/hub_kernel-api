require "json"

module HubKernel
  module Api
    class BreakingChangeError < StandardError; end

    module DescriptionCheck
      def self.check!(directory)
        problems = removals(directory) + unraised_additions(directory)
        raise BreakingChangeError, problems.join("\n") if problems.any?
      end

      def self.removals(directory)
        committed_majors(directory).flat_map do |major|
          missing(keyed(committed_hubs(directory, major)), keyed(current_hubs(major))).map { |path| "Major #{major.major} removes or renames #{path.join(".")}, which its committed file holds" }
        end
      end

      def self.unraised_additions(directory)
        committed_majors(directory).reject { |major| minor(major.version) > minor(committed(directory, major)["version"]) }.flat_map do |major|
          missing(keyed(current_hubs(major)), keyed(committed_hubs(directory, major))).map do |path|
            "Major #{major.major} adds #{path.join(".")} without raising its minor above #{committed(directory, major)["version"]}"
          end
        end
      end

      def self.committed_majors(directory) = HubKernel::Api.versions.reject(&:retired?).select { |major| File.exist?(file(directory, major)) }

      def self.file(directory, major) = File.join(directory, "v#{major.major}.json")

      def self.committed(directory, major) = JSON.parse(File.read(file(directory, major)))

      def self.committed_hubs(directory, major) = committed(directory, major)["hubs"]

      def self.current_hubs(major) = JSON.parse(Description.at(major).to_json)["hubs"]

      def self.minor(version) = version.split(".").second.to_i

      def self.keyed(value)
        case value
        when Hash then value.transform_values { |inner| keyed(inner) }
        when Array then value.to_h { |element| element.is_a?(Hash) ? [ element["name"], keyed(element) ] : [ element, {} ] }
        else { value => {} }
        end
      end

      def self.missing(held, current, path = [])
        held.flat_map { |key, inner| current.key?(key) ? missing(inner, current[key], path + [ key ]) : [ path + [ key ] ] }
      end

      private_class_method :unraised_additions, :committed_majors, :file, :committed, :committed_hubs, :current_hubs, :minor, :keyed, :missing
    end
  end
end
