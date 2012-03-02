---
title: Automatically Test Your Puppet Modules With rspec-puppet, puppet-lint And Travis CI
layout: post
categories:
 - puppet
 - puppet-lint
 - rspec-puppet
---

I'm going to assume you've got a Puppet module already on GitHub.  To save
messing around with bundler on your local machine, I recommend installing
`puppet-lint` and `rspec-puppet` as system gems while you're getting this all
set up.

{% highlight console linenos %}
$ gem install puppet-lint
$ gem install rspec-puppet
{% endhighlight %}

## rspec-puppet

First of all, let's create a directory structure for your spec files

{% highlight console linenos %}
$ mkdir -p spec/classes spec/defines spec/fixtures/manifests
$ mkdir -p spec/fixtures/modules/<your module name>
$ cd spec/fixtures/modules/<your module name>
$ touch spec/fixtures/manifests/init.pp
$ for i in files lib manifests templates; do ln -s ../../../../$i $i; done
{% endhighlight %}

If you're wondering about that last line, we symlink the contents of the module
into `spec/fixtures/modules/<your module name>` so that we can trick Puppet's
autoloader when running the specs.

Next, we need to configure rspec-puppet, so create `spec/spec_helper.rb` with
the following contents

{% highlight ruby linenos %}
require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
end
{% endhighlight %}

Now, all we need is a Rake task to fire up the tests.  Create a `Rakefile` in
the root directory of your module with the following contents

{% highlight ruby linenos %}
require 'rake'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*/*_spec.rb'
end
{% endhighlight %}

You can now run `rake spec` to run your `rspec-puppet` tests

## puppet-lint

Next up, we'll also get some automatic lint testing of your manifests going to
ensure you're writing manifests that comply with the Puppet Labs style guide.
This is simply a matter adding the following line near the top of your
`Rakefile`

{% highlight ruby linenos %}
require 'puppet-lint/tasks/puppet-lint'
{% endhighlight %}

You can now run `rake lint` to run puppet-lint over your manifests.

## Travis CI

[Travis CI](http://travis-ci.org) is a wonderful free continuous integration
service that integrates with [GitHub](https://github.com), running whatever
tests you want against your code every time you push.

To get Travis CI automatically testing your module you need to add a couple of
files to the root directory of your module.

First, create a `Gemfile` which tells bundler which ruby gems your tests need in
order to run.  If your module needs any additional gems, just add them to the
bottom of this file.

{% highlight ruby linenos %}
source :rubygems

if ENV.key?('PUPPET_VERSION')
  puppetversion = "= #{ENV['PUPPET_VERSION']}"
else
  puppetversion = ['>= 2.7']
end

gem 'rake'
gem 'puppet-lint'
gem 'rspec-puppet'
gem 'puppet', puppetversion
{% endhighlight %}

We also need to create `.travis.yml` which holds our Travis CI test config.

{% highlight yaml linenos %}
rvm: 1.8.7
notifications:
  email:
    - <your email address>
env:
  - PUPPET_VERSION=2.6.14
  - PUPPET_VERSION=2.7.11
{% endhighlight %}

This basically says, we want to use Ruby 1.8.7, run two sets of tests, one
against Puppet 2.6.14 and the other against Puppet 2.7.11 and email the
notifications through to your email address.

There's one last thing we need to do and that is create a default `rake` task
that runs both `rake spec` and `rake lint`.  To do that, add the following to
the end of your `Rakefile`.

{% highlight ruby linenos %}
task :default => [:spec, :lint]
{% endhighlight %}

If you haven't already done so, commit and push all this up to GitHub.

Point your browser [Travis CI](http://travis-ci.org) and login with your GitHub
account.  In your profile page, turn on tests for your module's repository.

![Turn on tests](https://img.skitch.com/20120302-e2y2xk2cxb6mwnuhhynrjfp7m8.jpg)

And wait for them to run!

![Win](https://img.skitch.com/20120302-txxietenui82dsxyjubajnqt2e.jpg)

## TL;DR

Go check out my [logrotate module](https://github.com/rodjek/puppet-logrotate) for
a working example.
