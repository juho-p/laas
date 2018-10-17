require 'fileutils'
require 'erb'
require 'yaml'
require 'date'
require 'bigdecimal'

LibDir = File.expand_path(File.dirname(__FILE__))
Rcfile = 'accounting.yml'

class Invoice
  def initialize(options)
    @options = options
  end

  def method_missing(m, *args)
    val = @options[m.to_sym]
    return val if val
    raise NotImplementedError.new(m)
  end

  def n s
    BigDecimal.new s.to_s.gsub(',', '.')
  end

  def val(sym)
    @options[sym]
  end

  def nval(sym)
    n(val(sym))
  end

  def vat
    n('0.24')
  end

  def vat_pct
    vat * 100
  end

  def total
    (nval(:unit_price) * nval(:amount)).round(2)
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

  def reference_number
    generate_reference("10#{nval(:number).to_i}")
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

  def num(x)
    x = BigDecimal.new(x.to_s)
    if x == x.round
      x.to_i
    else
      sprintf('%.2f', x).gsub('.', ',')
    end
  end

  def get_binding
    binding
  end
end

def generate(template_filename, options)
  erb = ERB.new(File.read(template_filename))
  context = Invoice.new(options)
  erb.result(context.get_binding)
end

def read_options(dir)
  defaults = {
    template: 'invoice.html.erb',
    config: File.join(dir, 'invoice.yml'),
  }

  cli_options = Hash[ARGV
    .map { |x| x.split('=') }
    .select { |x| x.size == 2 }
    .select { |x| [x[0].to_sym, x[1]] }
  ]

  config_file = defaults.merge(cli_options)[:config]
  config_options = Hash[YAML.load_file(config_file).map{|k,v| [k.to_sym, v]}]

  user_overrides = Hash[
    config_options[:invoice_overrides].map do |k|
      puts "#{k} (#{config_options[k]}):"
      [k, STDIN.readline.chomp]
    end]

  configuration = defaults
    .merge(config_options)
    .merge(cli_options)
    .merge(user_overrides)
end

def first_init
  files = Dir[File.join(LibDir, 'templates', '*')]
  files.each do |name|
    puts "Copy #{name}"
    FileUtils.cp(name, '.', preserve: true)
  end
end

def new_project(name)
  FileUtils.mkdir_p(name)

  Dir['*.template'].each do |file|
    FileUtils.cp(file, File.join(name, file.sub('.template', '')))
  end
end

def update!
  defaults = {}
  rc = YAML.load_file(Rcfile) rescue defaults
  yield rc
  File.write(Rcfile, YAML.dump(rc))
end

def set_number!(opts)
  update! do |rc|
    rc[:number] = (rc[:number] || 0) + 1
    opts[:number] = rc[:number]
  end
end

def new_file_base(dir)
  base = "#{Date.today.year}#{Date.today.month.to_s.rjust(2, '0')}"
  (0..1000).lazy
    .map { |i| "#{base}-#{i}" }
    .find { |x| Dir[x+'*'].empty? }
end

def new_invoice(project)
  opts = read_options(project)

  set_number! opts

  html = generate(opts[:template], opts)

  dir = File.join(project, 'invoices')
  FileUtils.mkdir_p dir
  basename = new_file_base(dir)
  file = ->(ext) { File.join(dir, basename + ext) }
  write = ->(ext, c) { File.write file[ext], c }
  
  write.call('.html', html)
  opts[:_now] = DateTime.now
  write.call('.yml', YAML.dump(opts))

  puts `wkhtmltopdf #{file['.html']} #{file['.pdf']}` rescue puts('wkhtmltopdf failed')
end
