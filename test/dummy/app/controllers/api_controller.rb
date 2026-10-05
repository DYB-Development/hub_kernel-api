class ApiController < ActionController::API
  private

  def current_person = request.headers["X-Person"]

  def current_account = request.headers["X-Account"]
end
