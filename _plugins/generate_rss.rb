module Jekyll
  class CategoryRSS < Page
    def initialize(site, base, dir, category)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.xml'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'rss.xml')
      self.data['category'] = category

      category_title_prefix = site.config['category_title_prefix'] || 'Category: '
      self.data['title'] = "#{category_title_prefix}#{category}"
    end
  end

  class CategoryRSSGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'rss'
        dir = site.config['feed_dir'] || 'feeds'
        site.categories.keys.each do |category|
          write_category_index(site, File.join(dir, category), category)
        end
      end
    end

    def write_category_index(site, dir, category)
      index = CategoryRSS.new(site, site.source, dir, category)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end
end
