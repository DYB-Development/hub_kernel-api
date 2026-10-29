module HubKernel
  module Api
    MajorVersion = Data.define(:version, :retired, :deprecated, :sunset) do
      def initialize(version:, retired: false, deprecated: false, sunset: nil) = super

      def major = version.split(".").first.to_i

      def retired? = retired

      def deprecated? = deprecated
    end
  end
end
