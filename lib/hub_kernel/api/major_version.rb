module HubKernel
  module Api
    MajorVersion = Data.define(:version, :retired) do
      def initialize(version:, retired: false) = super

      def major = version.split(".").first.to_i

      def retired? = retired
    end
  end
end
