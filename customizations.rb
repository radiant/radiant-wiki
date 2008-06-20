require 'junebug/ext/redcloth'

module Junebug::Views
  
  def layout
    if @skip_layout
      yield
    else
      html {
        head {
          title @page_title ? @page_title : @page.title
          link :href=> 'http://radiantcms.org/styles.css',      :type => 'text/css', :rel => 'stylesheet'
          link :href=> 'http://radiantcms.org/junebug.css',     :type => 'text/css', :rel => 'stylesheet'
          link :href=> Junebug.config['feedurl'], :rel => "alternate", :title => "Recently Updated Pages", :type => "application/atom+xml"
        }
        body {
          
          div :id => 'header' do
            div :id => 'logo' do
              a(:href => 'http://radiantcms.org/') do
                img :src => 'http://radiantcms.org/images/logo.gif', :alt => "Radiant - Content Management Simplified"
              end
            end
            div :id => 'site-links' do
              a(:href => 'http://radiantcms.org/') { text 'Home' }
              _separator
              a(:href => 'http://radiantcms.org/demo/') { text 'Demo' }
              _separator
              a(:href => 'http://radiantcms.org/download/') { text 'Download' }
              _separator
              strong { text 'Documentation' }
              _separator
              a(:href => 'http://dev.radiantcms.org/') { text 'Development' }
              _separator
              a(:href => 'http://radiantcms.org/blog/') { text 'Weblog' }
              _separator
              a(:href => 'http://radiantcms.org/podcast/') { text 'Podcast' }
            end
          end
          
          div :id => 'doc' do
            self << yield
          end
        }
      }
    end
  end


  def show
    _header (@version.version == @page.version ? :backlinks : :show)
    _body do
      h1 @page.title
      _markup @version.body
      div.buttons {
        _button 'Edit Page', R(Edit, @page.title_url, @version.version), { :accesskey => 'e' } if (@version.version == @page.version && (! @page.readonly || is_admin?))
        if is_admin?
          _button 'Delete', R(Delete, @page.title_url), {:onclick=>"return confirm('Sure you want to delete?')"} if @version.version == @page.version
          _button 'Revert To', R(Revert, @page.title_url, @version.version), {:onclick=>"return confirm('Sure you want to revert?')"} if @version.version != @page.version
        end
      }
      br :clear=> 'all'
      div :id => 'highlight' do
        p {
          text "<strong>Version #{@version.version}</strong> "
          text "(current) " if @version.version == @page.version
          _separator
          text 'Other versions: '
          a '« older', :href => R(Show, @page.title_url, @version.version-1) unless @version.version == 1
          text ' '
          a 'newer »', :href => R(Show, @page.title_url, @version.version+1) unless @version.version == @page.version
          text ' '
          a 'current', :href => R(Show, @page.title_url) unless @version.version == @page.version
          text ' '
          a 'versions', :href => R(Versions, @page.title_url)
          text "<br /> Page last edited by <b>#{@version.user.username}</b> on #{@page.updated_at.strftime('%B %d, %Y %I:%M %p')}"
          text " (#{diff_link(@page, @version)})" if @version.version > 1
          text '[Readonly] ' if @page.readonly
        }
      end
    end
    _footer { '' }
  end


  def edit
    _header :show
    _body do
      h1 @page_title
      div.formbox {
        form :method => 'post', :action => R(Edit, @page.title_url) do
          p { 
            label 'Page Title'
            input.textbox :value => @page.title, :name => 'post_title', :size => 30, 
                  :type => 'text'
            small " word characters (0-9A-Za-z), dashes, and spaces only"
          }
          p {
            a 'syntax help', :href => 'http://hobix.com/textile/', :target=>'_blank', :style => 'float: right;'
            label 'Page Content '
            textarea @page.body, :name => 'post_body', :rows => 17, :cols => 80
          }
          div.buttons {
            input.button :type => 'submit', :name => 'submit', :value => 'save', :accesskey => 's'
            input.button :type => 'submit', :name => 'submit', :value => 'minor edit', :accesskey => 'm' if @page.user_id == @state.user.id
            input.button :type => 'submit', :name => 'submit', :value => 'cancel'
            if is_admin?
              opts = { :type => 'checkbox', :value=>'1', :name => 'post_readonly' }
              opts[:checked] = 1 if @page.readonly
              input.checkbox opts
              text " Readonly "
              br
            end
          }
        end
        br :clear=>'all'
      }
    end
    _footer { '' }
  end


  def versions
    _header :show
    _body do
      h1 @page_title
      ul {
        @versions.each_with_index do |page,i|
          li {
            a "version #{page.version}", :href => R(Show, @page.title_url, page.version)
            text " (#{diff_link(@page, page)}) " if page.version > 1
            text' - edited '
            text last_updated(page)
            text ' ago by '
            strong page.user.username
            text ' (current)' if @page.version == page.version
          }
        end
      }
    end
    _footer { '' }
  end


  def search
    _header :show
    _body do
      h1 "Search Results for “#{@search_term}”"

      form :action => R(Search), :method => 'post' do
        input.textbox :name => 'q', :type => 'text', :value=>@search_term, :style => 'font-size: 99%; width: auto', :accesskey => 's' 
        input.button :type => 'submit', :name => 'search', :value => 'Search Again'
      end

      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title_url) } }
      }
    end
    _footer { '' }
  end


  def backlinks
    _header :show
    _body do
      h1 "Backlinks to #{@page.title}"
      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title) } }
      }
    end
    _footer { '' }
  end

  def orphans
    _header :show
    _body do
      h1 @page_title
      ul {
        @pages.each { |p|
          li{
            a p.title, :href => R(Show, p.title_url)
            text ' - empty page' if p.body.nil? or p.body.empty? 
          }
        }
      }
    end
    _footer { '' }
  end

  def users
    _header :static
    _body do
      h1 "Users"
      ul {
        @users.each { |u|
          li {
            a u.username, :href => R(Userinfo, u.username)
            text " - #{u.count} edits"
          }
        }
      }
    end
    _footer { '' }
  end

  def userinfo
    _header :static
    _body do
      h1 "Edit history: #{@user.username}"
      
      @groups.keys.sort.reverse.each { |key|
        @versions = @groups[key]
        h2 key
        ul {
          @versions.each { |pv|
            li{
              a pv.page.title, :href => R(Show, pv.page.title_url)
              text ", v#{pv.version}"
              text " (#{diff_link(pv.page, pv)}) " if pv.version > 1
              # text' - edited '
              # text last_updated(pv)
              # text ' ago'
            }
          }
        }
      }
    end
    _footer { '' }
  end

  def list
    _header :static
    _body do
      h1 "All wiki pages"
      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title_url) } }
      }
    end
    _footer { '' }
  end


  def recent
    _header :static
    _body do
      h1 "Changes in the Last 30 Days"
      page = @pages.shift 
      while page
        yday = page.updated_at.yday
        h2 page.updated_at.strftime('%B %d, %Y')
        ul {
          loop do
            li {
              a page.title, :href => R(Show, page.title_url)
              text ' ('
              a 'versions', :href => R(Versions, page.title_url)
              text ", #{diff_link(page)}" if page.version > 1
              text ') '
              span page.updated_at.strftime('%I:%M %p')
            }
            page = @pages.shift
            break unless page && (page.updated_at.yday == yday)
          end
        }
      end
    end
    _footer { '' }
  end
  
  def diff
    _header :show
    _body do
      p {
        text 'Comparing '
        span "version #{@v2.version}", :style => "background-color: #474; padding: 1px 4px;"
        text ' and '
        span "version #{@v1.version}", :style => "background-color: #744; padding: 1px 4px;"
        text ' '
      }
      pre.diff {
        text @difftext
      }
      p {
        a "Back to Page", :href => R(Show, @page.title_url)
      }
    end
    _footer { '' }
  end
  
  def login
    _body {
      div.login {
        h1 @page_title
        p.notice { @notice } if @notice
        form :action => R(Login), :method => 'post' do
          p {
            label 'Username', :for => 'username'
            input.textbox :name => 'username', :type => 'text', :value=>( @user ? @user.username : '')
          }

          p {
            label 'Password', :for => 'password'
            input.textbox :name => 'password', :type => 'password'
          }
        
          div.buttons {
            input :name => 'return_to', :type => 'hidden', :value=> @return_to
            input.button :type => 'submit', :name => 'login', :value => 'Login'
          }
        end
      }
    }
    _footer { '' }
  end

  def _button(text, href, options={})
    form :method=>:get, :action=>href do
      opts = {:type => 'submit', :name => 'submit', :value => text}.merge(options)
      input.button opts
    end
  end

  def _markup txt
    return '' if txt.blank?
    titles = Junebug::Models::Page.find(:all, :select => 'title').collect { |p| p.title }
    txt.gsub!(Junebug::Models::Page::PAGE_LINK) do
      page = title = $1
      title = $2 unless $2.empty?
      page_url = page.gsub(/ /, '_')
      if titles.include?(page)
        %Q{<a href="#{self/R(Show, page_url)}">#{title}</a>}
      else
        %Q{<span>#{title}<a href="#{self/R(Edit, page_url, 1)}">?</a></span>}
      end
    end
    #text RedCloth.new(auto_link_urls(txt), [ ]).to_html
    text RedCloth.new(txt, [ ]).to_html
  end

  def _header type
    div :id=>'hd' do
      
      span :id=>'userlinks' do
        if logged_in?
          text "You are logged in as: <strong>#{@state.user.username}</strong> &nbsp;("
          a 'Sign Out', :href=>"#{R(Logout)}?return_to=#{@env['REQUEST_URI']}"
          text ")"
        else
          a 'Sign In', :href=> "#{R(Login)}?return_to=#{@env['REQUEST_URI']}"
        end
      end

      span :id => 'search' do
        # text 'Search: '
        form :action => R(Search), :method => 'post' do
          div do
            input.textbox :name => 'q', :type => 'text', :value=>(''), :accesskey => 's' 
            input.button :type => 'submit', :name => 'search', :value => 'Search Wiki'
          end
        end
      end
   
      span :id => 'navlinks' do
        a 'Start Page',  :href => R(Show, Junebug.config['startpage'])
        _separator
        a 'Recent Changes', :href => R(Recent)
        _separator
        a 'All Pages', :href => R(List)
        _separator
        a 'Orphan Pages', :href => R(Orphans)
        _separator
        a 'Junebug Help', :href => R(Show, "Junebug_help") 
      end
      
      # if type == :static
      #   h1 page_title
      # elsif type == :backlinks
      #   h1 { a page_title, :href => R(Backlinks, page_title) }
      # else
      #   h1 { a page_title, :href => R(Show, page_title) }
      # end
      
    end
  end

  def _body
    div :id => 'bd' do
      div :id => 'content' do
        yield
      end
    end
  end

  def _footer
    div :id => 'footer' do
      yield
      p {
        a :href => Junebug.config['feedurl'] do
        img :src => '/images/feed-icon-14x14.png', :style => 'vertical-align: middle'
        end
        text ' '
        a :href => Junebug.config['feedurl'] do
          text "Recent Changes Feed"
        end
        _separator
        text 'Powered by '
        a 'Junebug Wiki', :href => 'http://www.junebugwiki.com/'
        text " <small>v#{Junebug::VERSION::STRING}</small>. "
      }
      p {
        text "Web Site Design, Logo, Etc. Copyright &copy; 2006&#8211;#{Date.today.year}, John W. Long. All Rights Reserved."
      }
    end
  end

  def _separator
    text ' '
    span(:class => 'separator') { text '|' }
    text ' '
  end

  def feed
    site_url = Junebug.config['siteurl'] || "http://#{Junebug.config['host']}:#{Junebug.config['port']}"
    site_domain = site_url.gsub(/^http:\/\//, '').gsub(/:/,'_')
    feed_url = site_url + R(Feed)

    xml = Builder::XmlMarkup.new(:target => self, :indent => 2)

    xml.instruct!
    xml.feed "xmlns"=>"http://www.w3.org/2005/Atom" do

      xml.title Junebug.config['feedtitle'] || "Wiki Updates"
      xml.id site_url
      xml.link "rel" => "self", "href" => feed_url

      pages = Junebug::Models::Page.find(:all, :order => 'updated_at DESC', :limit => 20)
      xml.updated pages.first.updated_at.xmlschema
      
      pages.each do |page|
        atom_id = "tag:#{site_domain},#{page.created_at.strftime("%Y-%m-%d")}:page/#{page.id}/#{page.version}"
        xml.entry do
          xml.id atom_id
          xml.title page.title
          xml.updated page.updated_at.xmlschema
          
          xml.author { xml.name page.user.username }
          xml.link "rel" => "alternate", "href" => site_url + R(Show, page.title_url)
          xml.summary :type=>'html' do
            xml.text! %|<a href="#{site_url + R(Show, page.title_url)}">#{page.title}</a> updated by #{page.user.username}|
            xml.text! %| (<a href="#{site_url + R(Diff,page.title_url,page.version-1,page.version)}">diff</a>)| if page.version > 1
            xml.text! "\n"
          end
          # xml.content do 
          #   xml.text! CGI::escapeHTML(page.body)+"\n"
          # end
        end
      end   
    end
  end

end
