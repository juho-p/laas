require 'test_helper'

class InvoiceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get invoice_index_url
    assert_response :success
  end

end
