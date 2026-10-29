module HubKernel
  module Api
    MajorVersion = Data.define(:version, :retired, :deprecated, :deprecated_on, :sunset) do
      def initialize(version:, retired: false, deprecated: false, deprecated_on: nil, sunset: nil) = super

      def major = version.split(".").first.to_i

      def retired? = retired

      def deprecated? = deprecated
    end
  end
end
