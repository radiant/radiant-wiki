#!/usr/local/bin/ruby

JUNEBUG_ROOT = ENV['JUNEBUG_ROOT'] ||= File.expand_path(File.dirname(__FILE__) + '/../') + '/'

%w(
  .
  vendor/junebug/lib
  vendor/camping/lib
  vendor/activesupport/lib
  vendor/markaby/lib
  vendor/fcgi
  vendor/activerecord/lib
).reverse.each { |dir| $:.unshift(JUNEBUG_ROOT + dir) }

require 'camping/fastcgi'  
require 'junebug/config'
require 'junebug'

class Camping::FastCGI
    def start
        FCGI.each do |req|
            dir, app = nil
            begin
                root, path = "/"
                if ENV['FORCE_ROOT'] and ENV['FORCE_ROOT'].to_i == 1
                  path, qs  = req.env['REQUEST_URI'].to_s.split('?', 2)
                  req.env['QUERY_STRING'] = qs
                else
                  root = req.env['SCRIPT_NAME']
                  path = req.env['PATH_INFO']
                end

                dir, app = @mounts.max { |a,b| match(path, a[0]) <=> match(path, b[0]) }
                unless dir and app
                    dir, app = '/', Camping
                end
                yield dir, app if block_given?

                req.env['SERVER_SCRIPT_NAME'] = req.env['SCRIPT_NAME']
                req.env['SERVER_PATH_INFO'] = req.env['PATH_INFO']
                req.env['SCRIPT_NAME'] = File.join(root, dir)
                req.env['PATH_INFO'] = path.gsub(/^#{dir}/, '')

                controller = app.run(req.in, req.env)
                sendfile = nil
                headers = {}
                controller.headers.each do |k, v|
                  if k =~ /^X-SENDFILE$/i and !ENV['SERVER_X_SENDFILE']
                    sendfile = v
                  else
                    headers[k] = v
                  end
                end

                body = controller.body
                controller.body = ""
                controller.headers = headers

                req.out << controller.to_s
                if sendfile
                  File.open(sendfile, "rb") do |f|
                    while chunk = f.read(CHUNK_SIZE) and chunk.length > 0
                      req.out << chunk
                    end
                  end
                elsif body.respond_to? :read
                  while chunk = body.read(CHUNK_SIZE) and chunk.length > 0
                    req.out << chunk
                  end
                  body.close if body.respond_to? :close
                else
                  req.out << body.to_s
                end
            rescue Exception => e
                req.out << "Content-Type: text/html\r\n\r\n" +
                    "<h1>Camping Problem!</h1>" +
                    "<h2><strong>#{root}</strong>#{path}</h2>" + 
                    "<h3>#{e.class} #{esc e.message}</h3>" +
                    "<ul>" + e.backtrace.map { |bt| "<li>#{esc bt}</li>" }.join + "</ul>" +
                    "<hr /><p>#{req.env.inspect}</p>"
            ensure
                req.finish
            end
        end
    end
end

FileUtils.cd ENV['JUNEBUG_ROOT'] do
  Junebug.connect
  Junebug.create
end
Camping::FastCGI.start(Junebug)
