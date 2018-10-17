Tool for creating Finnish invoices

### Installation

    gem build *.gemspec
    gem install *.gem

### Usage

    mkdir invoicing && cd invoicing
    lcli init
    # edit invoice.yml.template and invoice.html.erb files as needed
    lcli project my-new-project
    lcli invoice my-new-project
