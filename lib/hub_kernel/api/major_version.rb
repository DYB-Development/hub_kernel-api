module HubKernel
  module Api
    MajorVersion = Data.define(:version, :retired, :deprecated) do
      def initialize(version:, retired: false, deprecated: false) = super

      def major = version.split(".").first.to_i

      def retired? = retired

      def deprecated? = deprecated
    end
  end
end
