class InvoiceController < ApplicationController
  def index
    @invoice = Invoice.new(params)
  end

  def submit
    @invoice = Invoice.new invoice_params
    if @invoice.valid?
      if params[:button] == 'save'
        flash[:success] = I18n.t('form_saved')
        redirect_to invoice_index_path(invoice_params)
      else
        render pdf: 'invoice', layout: false, file: "#{Rails.root}/template/invoice.html.erb"
      end
    else
      flash[:error] = I18n.t('form_error')
      render :index
    end
  end

  private
  def invoice_params
    params[:invoice].permit(Invoice.attributes.keys)
  end
end
