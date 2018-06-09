require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  test 'generate reference number' do
    obj = Invoice.new({})
    assert_equal '1009', obj.generate_reference('100')
    assert_equal '1119', obj.generate_reference('111')
    assert_equal '1012', obj.generate_reference('101')
    assert_equal '1025', obj.generate_reference('102')
    assert_equal '1070', obj.generate_reference('107')
    assert_equal '2969', obj.generate_reference('296')
    assert_equal '12345672', obj.generate_reference('1234567')
  end

  test 'reference number is not too short' do
    obj = Invoice.new({})
    obj.number = 1
    assert(obj.reference_number.size >= 4)
  end
end
