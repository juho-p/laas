class Invoice
  include ActiveAttr::Model

  attribute :sender
  attribute :sender_ytunnus
  attribute :address
  attribute :receiver
  attribute :receiver_ytunnus
  attribute :number

  attribute :work_month

  attribute :unit_price
  attribute :amount

  attribute :account_number
  attribute :account_bic

  validates_numericality_of :unit_price, :amount
  validates_presence_of attributes.keys.map(&:to_sym)

  def initialize(attrs)
    super
    self.work_month = self.work_month || previous_month.to_s
    self.work_month = months_i18n(work_month) ? self.work_month.to_s.to_sym : nil
  end

  def previous_month
    (Date.today.month - 2) % 12 + 1
  end

  def n s
    BigDecimal.new s.gsub(',', '.')
  end

  def vat
    n('0.24')
  end

  def vat_pct
    vat * 100
  end

  def total
    (n(unit_price) * n(amount)).round(2)
  end

  def total_with_vat
    (total + total_vat).round(2)
  end

  def total_vat
    (total * vat).round(2)
  end

  def date
    d = DateTime.now
    "#{d.day}.#{d.month}.#{d.year}"
  end

  def work_date_description
    current = Date.today.month
    year = current < work_month.to_s.to_i ? (Date.today.year - 1) : Date.today.year
    I18n.t('work_month', month: months_i18n(work_month), year: year)
  end

  def reference_number
    generate_reference("10#{number.to_i}")
  end

  def generate_reference(x)
    digits = x.chars.map(&:to_i)

    sum = digits.reverse.
      zip([7,3,1].cycle).
      map{|a,b| a * b}.
      reduce(&:+)

    checksum = (10 - (sum % 10)) % 10

    x + checksum.to_s
  end

  def months_i18n(key)
    return nil if key.nil?
    lookup = I18n.t('simple_form.options.invoice.work_month')
    lookup.keys.any?{|k| k.to_s == key.to_s} ? lookup[key.to_s.to_sym] : 'invalid month'
  end
end
