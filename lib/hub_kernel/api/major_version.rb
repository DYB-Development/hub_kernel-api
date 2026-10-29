module HubKernel
  module Api
    MajorVersion = Data.define(:version) do
      def major = version.split(".").first.to_i
    end
  end
end
