require 'spec_helper'
require 'ronin/vulns/cli/web_vuln_command'
require 'ronin/vulns/sqli'

require 'stringio'
require 'tempfile'

describe Ronin::Vulns::CLI::WebVulnCommand do
  describe "#initialize" do
    it "must default #scan_mode to :first" do
      expect(subject.scan_mode).to eq(:first)
    end

    it "must default #scan_kwargs to {}" do
      expect(subject.scan_kwargs).to eq({})
    end
  end

  describe "#scan_kwargs" do
    it "must default to an empty Hash" do
      expect(subject.scan_kwargs).to eq({})
    end
  end

  describe "#request_method" do
    it "must default to nil" do
      expect(subject.request_method).to be(nil)
    end
  end

  describe "#request_method=" do
    let(:http_method) { :post }

    before { subject.request_method = http_method }

    it "must set #request_method" do
      expect(subject.request_method).to eq(http_method)
    end

    it "must set :request_method in #scan_kwargs" do
      expect(subject.scan_kwargs[:request_method]).to eq(http_method)
    end
  end

  describe "#headers" do
    it "must default to an empty Hash" do
      expect(subject.headers).to eq({})
    end

    it "must set :headers in #scan_kwargs" do
      subject.headers

      expect(subject.scan_kwargs[:headers]).to be(subject.headers)
    end
  end

  describe "#user_agent" do
    it "must default to nil" do
      expect(subject.user_agent).to be(nil)
    end
  end

  describe "#user_agent=" do
    let(:new_user_agent) { 'Mozilla/5.0 Foo Bar' }

    before { subject.user_agent = new_user_agent }

    it "must set #user_agent" do
      expect(subject.user_agent).to eq(new_user_agent)
    end

    it "must set :user_agent in #scan_kwargs" do
      expect(subject.scan_kwargs[:user_agent]).to eq(new_user_agent)
    end
  end

  describe "#cookie" do
    it "must default to an empty Ronin::Support::Network::HTTP::Cookie" do
      expect(subject.cookie).to be_kind_of(Ronin::Support::Network::HTTP::Cookie)
      expect(subject.cookie).to be_empty
    end

    it "must set :cookie in #scan_kwargs" do
      subject.cookie

      expect(subject.scan_kwargs[:cookie]).to be(subject.cookie)
    end
  end

  describe "#referer" do
    it "must default to nil" do
      expect(subject.referer).to be(nil)
    end
  end

  describe "#referer=" do
    let(:new_referer)  { 'https://example.com/' }

    before { subject.referer = new_referer }

    it "must set #referer" do
      expect(subject.referer).to eq(new_referer)
    end

    it "must set :referer in #scan_kwargs" do
      expect(subject.scan_kwargs[:referer]).to eq(new_referer)
    end
  end

  describe "#form_data" do
    it "must default to an empty Hash" do
      expect(subject.form_data).to eq({})
    end

    it "must set :form_data in #scan_kwargs" do
      subject.form_data

      expect(subject.scan_kwargs[:form_data]).to be(subject.form_data)
    end
  end

  describe "#test_query_params" do
    it "must default to an empty Set" do
      expect(subject.test_query_params).to eq(Set.new)
    end

    it "must set :query_params in #scan_kwargs" do
      subject.test_query_params

      expect(subject.scan_kwargs[:query_params]).to be(subject.test_query_params)
    end
  end

  describe "#test_query_params=" do
    context "when given true" do
      before { subject.test_query_params = true }

      it "must set #test_query_params to true" do
        expect(subject.test_query_params).to be(true)
      end

      it "must set :query_params in #scan_kwargs to true" do
        expect(subject.scan_kwargs[:query_params]).to be(true)
      end
    end
  end

  describe "#test_header_names" do
    it "must default to an empty Hash" do
      expect(subject.test_header_names).to eq(Set.new)
    end

    it "must set :header_names in #scan_kwargs" do
      subject.test_header_names

      expect(subject.scan_kwargs[:header_names]).to be(subject.test_header_names)
    end
  end

  describe "#test_cookie_params" do
    it "must default to an empty Set" do
      expect(subject.test_cookie_params).to eq(Set.new)
    end

    it "must set :cookie_params in #scan_kwargs" do
      subject.test_cookie_params

      expect(subject.scan_kwargs[:cookie_params]).to be(subject.test_cookie_params)
    end
  end

  describe "#test_cookie_params=" do
    context "when given true" do
      before { subject.test_cookie_params = true }

      it "must set #test_cookie_params to true" do
        expect(subject.test_cookie_params).to be(true)
      end

      it "must set :cookie_params in #scan_kwargs to true" do
        expect(subject.scan_kwargs[:cookie_params]).to be(true)
      end
    end
  end

  describe "#test_form_params" do
    it "must default to an empty Set" do
      expect(subject.test_form_params).to eq(Set.new)
    end

    it "must set :form_params in #scan_kwargs" do
      subject.test_form_params

      expect(subject.scan_kwargs[:form_params]).to be(subject.test_form_params)
    end
  end

  describe "#option_parser" do
    before { subject.option_parser.parse(argv) }

    context "when the '--first' option is parsed" do
      let(:argv) { %w[--first] }

      it "must set #scan_mode to :first" do
        expect(subject.scan_mode).to eq(:first)
      end
    end

    context "when the '--all' option is parsed" do
      let(:argv) { %w[--all] }

      it "must set #scan_mode to :all" do
        expect(subject.scan_mode).to eq(:all)
      end
    end

    context "when the '--header \"Name: value\"' option is parsed" do
      let(:header_name)  { 'X-Foo' }
      let(:header_value) { 'bar'   }

      let(:argv) { ['--header', "#{header_name}: #{header_value}"] }

      it "must set #headers to a Hash" do
        expect(subject.headers).to be_kind_of(Hash)
      end

      it "must add the header name and value to #headers" do
        expect(subject.headers[header_name]).to eq(header_value)
      end
    end

    context "when the '--cookie \"...\"' option is parsed" do
      let(:cookie_name1)  { 'a' }
      let(:cookie_value1) { '1' }
      let(:cookie_name2)  { 'b' }
      let(:cookie_value2) { '2' }
      let(:cookie) do
        "#{cookie_name1}=#{cookie_value1}; #{cookie_name2}=#{cookie_value2}"
      end

      let(:argv) { ['--cookie', cookie] }

      it "must set #cookie to the parsed Ronin::Support::Network::HTTP::Cookie" do
        expect(subject.cookie).to be_kind_of(Ronin::Support::Network::HTTP::Cookie)
        expect(subject.cookie.to_h).to eq(
          {
            cookie_name1 => cookie_value1,
            cookie_name2 => cookie_value2
          }
        )
      end

      context "when #cookie is already set" do
        let(:cookie_name3)  { 'c' }
        let(:cookie_value3) { '3' }
        let(:cookie_name4)  { 'a' }
        let(:cookie_value4) { 'x' }
        let(:cookie2) do
          "#{cookie_name3}=#{cookie_value3}; #{cookie_name4}=#{cookie_value4}"
        end

        let(:argv) { ['--cookie', cookie, '--cookie', cookie2] }

        it "must merged the parsed cookie params into #cookie" do
          expect(subject.cookie).to be_kind_of(Ronin::Support::Network::HTTP::Cookie)
          expect(subject.cookie.to_h).to eq(
            {
              cookie_name2 => cookie_value2,
              cookie_name3 => cookie_value3,
              cookie_name4 => cookie_value4
            }
          )
        end
      end
    end

    context "when the '--cookie-param name=value' option is parsed" do
      let(:cookie_name)  { 'a' }
      let(:cookie_value) { '1' }

      let(:argv) { ['--cookie-param', "#{cookie_name}=#{cookie_value}"] }

      it "must set #cookie to a Ronin::Support::Network::HTTP::Cookie containing the parsed name and param" do
        expect(subject.cookie).to be_kind_of(Ronin::Support::Network::HTTP::Cookie)
        expect(subject.cookie.to_h).to eq(
          {
            cookie_name => cookie_value
          }
        )
      end

      context "when #cookie is already set" do
        let(:cookie_name2)  { 'b' }
        let(:cookie_value2) { '2' }
        let(:cookie_name3)  { 'a' }
        let(:cookie_value3) { 'x' }

        let(:argv) do
          [
            '--cookie-param', "#{cookie_name}=#{cookie_value}",
            '--cookie-param', "#{cookie_name2}=#{cookie_value2}",
            '--cookie-param', "#{cookie_name3}=#{cookie_value3}"
          ]
        end

        it "must merged the parsed cookie params into #cookie" do
          expect(subject.cookie).to be_kind_of(Ronin::Support::Network::HTTP::Cookie)
          expect(subject.cookie.to_h).to eq(
            {
              cookie_name2 => cookie_value2,
              cookie_name3 => cookie_value3
            }
          )
        end
      end
    end

    context "when the '--referer <URL>' option is parsed" do
      let(:referer)  { 'https://example.com/' }
      let(:argv)     { ['--referer', referer] }

      it "must set #referer" do
        expect(subject.referer).to eq(referer)
      end
    end

    context "when the '--form-param name=value' option is parsed" do
      let(:param_name)  { 'foo' }
      let(:param_value) { 'bar' }

      let(:argv) { ['--form-param', "#{param_name}=#{param_value}"] }

      it "must set #form_data to a Hash" do
        expect(subject.form_data).to be_kind_of(Hash)
      end

      it "must add the param name and value to #form_data" do
        expect(subject.form_data[param_name]).to eq(param_value)
      end
    end

    context "when the '--test-query-param <name>' option is parsed" do
      let(:query_param) { 'id' }

      let(:argv) { ['--test-query-param', query_param] }

      it "must set #test_query_params to a Set" do
        expect(subject.test_query_params).to be_kind_of(Set)
      end

      it "must add the query param name to #test_query_params" do
        expect(subject.test_query_params).to include(query_param)
      end
    end

    context "when the '--test-all-query-param' option is parsed" do
      let(:argv) { %w[--test-all-query-param] }

      it "must set #test_query_params to true" do
        expect(subject.test_query_params).to be(true)
      end
    end

    context "when the '--test-header-name <name>' option is parsed" do
      let(:header_name) { 'X-Foo' }

      let(:argv) { ['--test-header-name', header_name] }

      it "must set #test_header_names to a Set" do
        expect(subject.test_header_names).to be_kind_of(Set)
      end

      it "must add the query param name to #test_header_names" do
        expect(subject.test_header_names).to include(header_name)
      end
    end

    context "when the '--test-cookie-param <name>' option is parsed" do
      let(:cookie_param) { 'session_id' }

      let(:argv) { ['--test-cookie-param', cookie_param] }

      it "must set #test_cookie_params to a Set" do
        expect(subject.test_cookie_params).to be_kind_of(Set)
      end

      it "must add the query param name to #test_cookie_params" do
        expect(subject.test_cookie_params).to include(cookie_param)
      end
    end

    context "when the '--test-all-cookie-param' option is parsed" do
      let(:argv) { %w[--test-all-cookie-param] }

      it "must set #test_cookie_params to true" do
        expect(subject.test_cookie_params).to be(true)
      end
    end

    context "when the '--test-form-param <name>' option is parsed" do
      let(:form_param) { 'id' }

      let(:argv) { ['--test-form-param', form_param] }

      it "must set #test_form_params to a Set" do
        expect(subject.test_form_params).to be_kind_of(Set)
      end

      it "must add the query param name to #test_form_params" do
        expect(subject.test_form_params).to include(form_param)
      end
    end
  end

  let(:url) { 'https://example.com/page.php?id=1' }

  describe "#run" do
    let(:url1) { 'https://example.com/page1' }
    let(:url2) { 'https://example.com/page2' }

    context "when given URL arguments" do
      let(:urls) { [url1, url2] }

      it "must call #process_url with each URL argument" do
        expect(subject).to receive(:process_url).with(url1)
        expect(subject).to receive(:process_url).with(url2)

        subject.run(*urls)
      end

      context "and no vulnerabilities are discovered on any of the URLs" do
        it "must print a 'No vulnerabilities found' message" do
          expect(subject).to receive(:process_url).with(url1).and_return(false)
          expect(subject).to receive(:process_url).with(url2).and_return(false)
          expect(subject).to receive(:puts).with(
            subject.colors.green('No vulnerabilities found')
          )

          subject.run(*urls)
        end
      end

      context "when given the --import option" do
        let(:argv) { ['--import'] }
        before { subject.option_parser.parse(argv) }

        it "must call #db_connect before calling #process_url with the URLs" do
          expect(subject).to receive(:db_connect)
          expect(subject).to receive(:process_url).with(url1)
          expect(subject).to receive(:process_url).with(url2)

          subject.run(*urls)
        end
      end
    end

    context "when given the '--input FILE' option" do
      let(:tempfile) { Tempfile.new(['ronin-vulns-input-file', '.txt']) }

      before do
        tempfile.puts(url1)
        tempfile.puts(url2)
        tempfile.flush
      end

      let(:argv) { ['--input', tempfile.path] }
      before { subject.option_parser.parse(argv) }

      it "must read the FILE and pass each line to #process_url" do
        expect(subject).to receive(:process_url).with(url1)
        expect(subject).to receive(:process_url).with(url2)

        subject.run
      end

      context "and no vulnerabilities are discovered on any of the URLs" do
        it "must print a 'No vulnerabilities found' message" do
          expect(subject).to receive(:process_url).with(url1).and_return(false)
          expect(subject).to receive(:process_url).with(url2).and_return(false)
          expect(subject).to receive(:puts).with(
            subject.colors.green('No vulnerabilities found')
          )

          subject.run
        end
      end

      context "when given the --import option" do
        let(:argv) { ['--import', '--input', tempfile.path] }
        before { subject.option_parser.parse(argv) }

        it "must call #db_connect before calling #process_url with the URLs" do
          expect(subject).to receive(:db_connect)
          expect(subject).to receive(:process_url).with(url1)
          expect(subject).to receive(:process_url).with(url2)

          subject.run
        end
      end
    end

    context "when given neither URL arguments or '--input FILE'" do
      it "must print an error and exit with -1" do
        expect(subject).to receive(:print_error).with("must specify URL(s) or --input")
        expect(subject).to receive(:exit).with(-1)

        subject.run
      end
    end
  end

  describe "#print_vulns" do
    let(:stdout) { StringIO.new }

    subject { described_class.new(stdout: stdout) }
    before { allow(stdout).to receive(:tty?).and_return(true) }

    let(:green)             { CommandKit::Colors::ANSI::GREEN }
    let(:bright_red)        { CommandKit::Colors::ANSI::BRIGHT_RED }
    let(:bright_white)      { CommandKit::Colors::ANSI::BRIGHT_WHITE }
    let(:bold)              { CommandKit::Colors::ANSI::BOLD }
    let(:bold_bright_red)   { bold + bright_red }
    let(:bold_bright_white) { bold + bright_white }
    let(:reset_intensity)   { CommandKit::Colors::ANSI::RESET_INTENSITY }
    let(:reset_color)       { CommandKit::Colors::ANSI::RESET_COLOR }
    let(:reset)             { reset_color + reset_intensity }

    context "when given an empty Array" do
      let(:vulns) { [] }

      it "must print 'No vulnerabilities found' in green" do
        subject.print_vulns(vulns)

        expect(stdout.string).to eq(
          "#{green}No vulnerabilities found#{reset_color}#{$/}"
        )
      end
    end

    context "when given an Array of Ronin::Vulns::WebVuln objects" do
      let(:query_param1) { 'a' }
      let(:query_param2) { 'b' }
      let(:url) { URI.parse("https://example.com/page.php?#{query_param1}=foo&#{query_param2}=bar") }

      let(:vuln1) { Ronin::Vulns::SQLI.new(url, query_param: query_param1) }
      let(:vuln2) { Ronin::Vulns::SQLI.new(url, query_param: query_param2) }
      let(:vulns) { [vuln1, vuln2] }

      it "must print 'No vulnerabilities found' in green" do
        subject.print_vulns(vulns)

        expect(stdout.string).to eq(
          [
            "#{bold_bright_red}Vulnerabilities found!#{reset}",
            '',
            "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param1}#{reset}'",
            "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param2}#{reset}'",
            '',
            ''
          ].join($/)
        )
      end

      context "and when the '--print-curl' option is given" do
        before { subject.options[:print_curl] = true }

        it "must print an indented example curl command for each web vulnerability" do
          subject.print_vulns(vulns)

          expect(stdout.string).to eq(
            [
              "#{bold_bright_red}Vulnerabilities found!#{reset}",
              '',
              "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param1}#{reset}'",
              '',
              "    #{vuln1.to_curl}",
              '',
              "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param2}#{reset}'",
              '',
              "    #{vuln2.to_curl}",
              '',
              ''
            ].join($/)
          )
        end
      end

      context "and when the '--print'http' option is given" do
        before { subject.options[:print_http] = true }

        it "must print an indented example HTTP request for each web vulnerability" do
          subject.print_vulns(vulns)

          expect(stdout.string).to eq(
            [
              "#{bold_bright_red}Vulnerabilities found!#{reset}",
              '',
              "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param1}#{reset}'",
              '',
              *vuln1.to_http.each_line(chomp: true).map { |line|
                "    #{line}"
              },
              '',
              "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param2}#{reset}'",
              '',
              *vuln2.to_http.each_line(chomp: true).map { |line|
                "    #{line}"
              },
              '',
              ''
            ].join($/)
          )
        end
      end

      context "and when given both the '--print'curl' and '--print-http' options are given" do
        before do
          subject.options[:print_curl] = true
          subject.options[:print_http] = true
        end

        it "must print an indented example curl command and then an example HTTP request for each web vulnerability" do
          subject.print_vulns(vulns)

          expect(stdout.string).to eq(
            [
              "#{bold_bright_red}Vulnerabilities found!#{reset}",
              '',
              "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param1}#{reset}'",
              '',
              "    #{vuln1.to_curl}",
              '',
              *vuln1.to_http.each_line(chomp: true).map { |line|
                "    #{line}"
              },
              '',
              "  #{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param2}#{reset}'",
              '',
              "    #{vuln2.to_curl}",
              '',
              *vuln2.to_http.each_line(chomp: true).map { |line|
                "    #{line}"
              },
              '',
              ''
            ].join($/)
          )
        end
      end
    end
  end

  describe "#print_vuln" do
    let(:stdout) { StringIO.new }

    subject { described_class.new(stdout: stdout) }
    before { allow(stdout).to receive(:tty?).and_return(true) }

    let(:bright_red)        { CommandKit::Colors::ANSI::BRIGHT_RED }
    let(:bright_white)      { CommandKit::Colors::ANSI::BRIGHT_WHITE }
    let(:bold)              { CommandKit::Colors::ANSI::BOLD }
    let(:bold_bright_red)   { bold + bright_red }
    let(:bold_bright_white) { bold + bright_white }
    let(:reset_intensity)   { CommandKit::Colors::ANSI::RESET_INTENSITY }
    let(:reset_color)       { CommandKit::Colors::ANSI::RESET_COLOR     }
    let(:reset)             { reset_color + reset_intensity }

    context "when the '--print-curl' option is given" do
      let(:query_param) { 'id' }
      let(:vuln) { Ronin::Vulns::SQLI.new(url, query_param: query_param) }

      before { subject.options[:print_curl] = true }

      it "must print an indented example curl command for the web vulnerability" do
        subject.print_vuln(vuln)

        expect(stdout.string).to eq(
          [
            "#{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param}#{reset}'",
            '',
            "  #{vuln.to_curl}",
            '',
            ''
          ].join($/)
        )
      end
    end

    context "when the '--print'http' option is given" do
      let(:query_param) { 'id' }
      let(:vuln) { Ronin::Vulns::SQLI.new(url, query_param: query_param) }

      before { subject.options[:print_http] = true }

      it "must print an indented example HTTP request for the web vulnerability" do
        subject.print_vuln(vuln)

        expect(stdout.string).to eq(
          [
            "#{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param}#{reset}'",
            '',
            *vuln.to_http.each_line(chomp: true).map { |line|
              "  #{line}"
            },
            '',
            ''
          ].join($/)
        )
      end
    end

    context "when given both the '--print'curl' and '--print-http' options are given" do
      let(:query_param) { 'id' }
      let(:vuln) { Ronin::Vulns::SQLI.new(url, query_param: query_param) }

      before do
        subject.options[:print_curl] = true
        subject.options[:print_http] = true
      end

      it "must print an indented example curl command and then an example HTTP request for the web vulnerability" do
        subject.print_vuln(vuln)

        expect(stdout.string).to eq(
          [
            "#{bold_bright_red}SQLi#{reset} on #{bold_bright_white}#{url}#{reset} via #{bold_bright_white}query param#{reset} '#{bold_bright_red}#{query_param}#{reset}'",
            '',
            "  #{vuln.to_curl}",
            '',
            *vuln.to_http.each_line(chomp: true).map { |line|
              "  #{line}"
            },
            '',
            ''
          ].join($/)
        )
      end
    end
  end

  describe "#process_url" do
    context "when #scan_mode is :first" do
      it "must call #test_url with the given URL" do
        expect(subject).to receive(:test_url).with(url)

        expect { |b|
          subject.process_url(url,&b)
        }.to_not yield_control
      end

      context "and #test_url returns a WebVuln object" do
        let(:vuln) { double('first returned WebVuln') }

        it "must call #process_vuln with the WebVuln object" do
          expect(subject).to receive(:test_url).with(url).and_return(vuln)
          expect(subject).to receive(:process_vuln).with(vuln)

          expect { |b|
            subject.process_url(url,&b)
          }.to yield_with_args(vuln)
        end
      end
    end

    context "when #scan_mode is :all" do
      let(:argv) { ['--all'] }
      before { subject.option_parser.parse(argv) }

      it "must call #scan_url with the given URL" do
        expect(subject).to receive(:scan_url).with(url)

        subject.process_url(url)
      end

      context "and #scan_url yields WebVuln objects" do
        let(:vuln1) { double('yielded WebVuln 1') }
        let(:vuln2) { double('yielded WebVuln 2') }

        it "must call #process_vuln with the yielded WebVuln objects" do
          expect(subject).to receive(:scan_url).with(url).and_yield(vuln1).and_yield(vuln2)
          expect(subject).to receive(:process_vuln).with(vuln1)
          expect(subject).to receive(:process_vuln).with(vuln2)

          expect { |b|
            subject.process_url(url,&b)
          }.to yield_successive_args(vuln1,vuln2)
        end
      end
    end

    context "when the given URL is an IP address" do
      let(:url) { "127.0.0.1" }

      it do
        expect(subject).to receive(:print_error).with(
          "URL must start with http:// or https://: #{url.inspect}"
        )

        expect {
          subject.process_url(url)
        }.to raise_error(SystemExit)
      end
    end

    context "when the given URL is a hostname" do
      let(:url) { "example.com" }

      it do
        expect(subject).to receive(:print_error).with(
          "URL must start with http:// or https://: #{url.inspect}"
        )

        expect {
          subject.process_url(url)
        }.to raise_error(SystemExit)
      end
    end

    context "when the given URL does not start with http:// or https://" do
      let(:url) { "foo://" }

      it do
        expect(subject).to receive(:print_error).with(
          "URL must start with http:// or https://: #{url.inspect}"
        )

        expect {
          subject.process_url(url)
        }.to raise_error(SystemExit)
      end
    end
  end

  describe "#process_vuln" do
    let(:vuln) { double('WebVuln object') }

    it "must call #log_vuln with the given vuln object" do
      expect(subject).to receive(:log_vuln).with(vuln)

      subject.process_vuln(vuln)
    end

    context "when options[:import] is true" do
      before { subject.options[:import] = true }

      it "must call #log_vuln and then #import_vuln with the vuln object" do
        expect(subject).to receive(:log_vuln).with(vuln)
        expect(subject).to receive(:import_vuln).with(vuln)

        subject.process_vuln(vuln)
      end
    end
  end

  describe "#scan_kwargs" do
    it "must return an empty Hash by default" do
      expect(subject.scan_kwargs).to eq({})
    end

    context "when #request_method is set" do
      let(:argv) { ['--request-method', "POST"] }
      before { subject.option_parser.parse(argv) }

      it "must set the :request_method key in the Hash" do
        expect(subject.scan_kwargs[:request_method]).to eq(:post)
      end
    end

    context "when #headers is set" do
      let(:header_name)  { 'X-Foo' }
      let(:header_value) { 'bar'   }

      let(:argv) { ['--header', "#{header_name}: #{header_value}"] }
      before { subject.option_parser.parse(argv) }

      it "must set the :headers key in the Hash" do
        expect(subject.scan_kwargs[:headers]).to eq(subject.headers)
      end
    end

    context "when #cookie is set" do
      let(:param_name)  { 'foo' }
      let(:param_value) { 'bar' }

      let(:argv) { ['--cookie-param', "#{param_name}=#{param_value}"] }
      before { subject.option_parser.parse(argv) }

      it "must set the :cookie key in the Hash" do
        expect(subject.scan_kwargs[:cookie]).to eq(subject.cookie)
      end
    end

    context "when #referer is set" do
      let(:referer)  { 'https://example.com/' }

      let(:argv)     { ['--referer', referer] }
      before { subject.option_parser.parse(argv) }

      it "must set the :referer key in the Hash" do
        expect(subject.scan_kwargs[:referer]).to eq(subject.referer)
      end
    end

    context "when #form_data is set" do
      let(:param_name)  { 'foo' }
      let(:param_value) { 'bar' }

      let(:argv) { ['--form-param', "#{param_name}=#{param_value}"] }
      before { subject.option_parser.parse(argv) }

      it "must set the :form_data key in the Hash" do
        expect(subject.scan_kwargs[:form_data]).to eq(subject.form_data)
      end
    end

    context "when #test_query_params is set" do
      let(:query_param) { 'id' }

      let(:argv) { ['--test-query-param', query_param] }
      before { subject.option_parser.parse(argv) }

      it "must set the :query_params key in the Hash" do
        expect(subject.scan_kwargs[:query_params]).to eq(subject.test_query_params)
      end
    end

    context "when #test_all_query_params is set" do
      let(:argv) { %w[--test-all-query-param] }
      before { subject.option_parser.parse(argv) }

      it "must set the :query_params key in the Hash to true" do
        expect(subject.scan_kwargs[:query_params]).to be(true)
      end
    end

    context "when #test_header_names is set" do
      let(:header_name) { 'X-Foo' }

      let(:argv) { ['--test-header-name', header_name] }
      before { subject.option_parser.parse(argv) }

      it "must set the :header_names key in the Hash" do
        expect(subject.scan_kwargs[:header_names]).to eq(subject.test_header_names)
      end
    end

    context "when #test_cookie_params is set" do
      let(:cookie_param) { 'session_id' }

      let(:argv) { ['--test-cookie-param', cookie_param] }
      before { subject.option_parser.parse(argv) }

      it "must set the :cookie_params key in the Hash" do
        expect(subject.scan_kwargs[:cookie_params]).to eq(subject.test_cookie_params)
      end
    end

    context "when #test_all_cookie_params is set" do
      let(:argv) { %w[--test-all-cookie-param] }
      before { subject.option_parser.parse(argv) }

      it "must set the :cookie_params key in the Hash to true" do
        expect(subject.scan_kwargs[:cookie_params]).to be(true)
      end
    end

    context "when #test_all_form_params is set" do
      let(:argv) { %w[--test-all-form-param] }
      before { subject.option_parser.parse(argv) }

      it "must set the :form_params key in the Hash to true" do
        expect(subject.scan_kwargs[:form_params]).to be(true)
      end
    end

    context "when #test_form_params is set" do
      let(:form_param) { 'id' }

      let(:argv) { ['--test-form-param', form_param] }
      before { subject.option_parser.parse(argv) }

      it "must set the :form_params key in the Hash" do
        expect(subject.scan_kwargs[:form_params]).to eq(subject.test_form_params)
      end
    end
  end

  describe "#scan_url" do
    it do
      expect {
        subject.scan_url(url)
      }.to raise_error(NotImplementedError,"#{described_class}#scan_url was not defined")
    end
  end

  describe "#test_url" do
    it do
      expect {
        subject.test_url(url)
      }.to raise_error(NotImplementedError,"#{described_class}#test_url was not defined")
    end
  end
end
