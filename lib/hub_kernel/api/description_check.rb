require "json"

module HubKernel
  module Api
    module DescriptionCheck
      def self.removals(directory)
        committed_majors(directory).flat_map do |major|
          missing(keyed(committed_hubs(directory, major)), keyed(current_hubs(major))).map { |path| "Major #{major.major} removes or renames #{path.join(".")}, which its committed file holds" }
        end
      end

      def self.committed_majors(directory) = HubKernel::Api.versions.select { |major| File.exist?(file(directory, major)) }

      def self.file(directory, major) = File.join(directory, "v#{major.major}.json")

      def self.committed_hubs(directory, major) = JSON.parse(File.read(file(directory, major)))["hubs"]

      def self.current_hubs(major) = JSON.parse(Description.at(major).to_json)["hubs"]

      def self.keyed(value)
        case value
        when Hash then value.transform_values { |inner| keyed(inner) }
        when Array then value.to_h { |element| [ element["name"], keyed(element) ] }
        else { value => {} }
        end
      end

      def self.missing(held, current, path = [])
        held.flat_map { |key, inner| current.key?(key) ? missing(inner, current[key], path + [ key ]) : [ path + [ key ] ] }
      end

      private_class_method :committed_majors, :file, :committed_hubs, :current_hubs, :keyed, :missing
    end
  end
end
