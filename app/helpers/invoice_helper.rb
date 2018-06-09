module InvoiceHelper
  def num(x)
    x = BigDecimal.new(x)
    if x == x.round
      x.to_i
    else
      sprintf('%.2f', x).gsub('.', ',')
    end
  end
end
