require 'fileutils'

task :publish do
  tmp_site_dir = `/usr/bin/mktemp -d /tmp/site.XXXXXXXXXX`
    `jekyll --no-server --no-auto --no-safe #{tmp_site_dir}`
    `git checkout master`
    FileUtils.cp_r("#{tmp_site_dir}/", './')
    `git add .`
    `git commit -a -m "updated site"`
    `rm -rf #{tmp_site_dir}`
end
