---
layout: post
title: Test Your Puppet Modules - Functions
categories:
- puppet
- rspec
- testing
---

{% highlight irc linenos %}
11:00 <hubot> [puppet/master] merge branch 'mysql-module-refactor' - dave
11:00 <hubot> dave is deploying puppet/master to production
11:23 <nagios> PROBLEM - MySQL on dbmaster1.initech.com is CRITICAL
11:24 <dave> oh fuck
{% endhighlight %}

Look familiar?

If you've worked with configuration management systems for a while, a situation
like this has probably cropped up and ruined your day.  If you're lucky
enough to have a homogeneous environment, then you might have a staging
environment that you can test changes out on, but what if you don't?  A slight
mistake in that harmless change you're working on could stop a service on
hundreds of machines or worse (purge the mysql-server package and all it's data
\*cough\*).

## Why you should be writing unit tests for your Puppet modules

 * Prevent situations like the one above.
 * Catch any problems moving between Puppet releases before it hits production.
 * Now we can do this too

![Obligatory XKCD](http://imgs.xkcd.com/comics/compiling.png)

## Getting started

In this article, we'll cover setting up your testing environment and cover how
to write unit tests for your Puppet functions.  I'm going to make a few
assumptions now:

 * You store your Puppet manifests in git.
 * You run a \*nix machine as your workstation.
 * You don't mind getting your hands dirty with a bit of simple Ruby.
 * You have Ruby installed (1.8.7).

First of all, we're going to install [Bundler](http://gembundler.com) to manage
the dependencies our Puppet testing rig will have.

{% highlight console linenos %}
$ gem install bundler --no-ri --no-rdoc
Fetching: bundler-1.0.21.gem (100%)
Successfully installed bundler-1.0.21
1 gem installed
$ bundle --version
Bundler version 1.0.21
{% endhighlight %}

Next we're going to create a `Gemfile` in the top level of our Puppet repo with
the list of gems we're going to need.  Adjust the `puppet` and `facter`
versions to match your environment.

{% highlight ruby linenos %}
source :rubygems

gem 'puppet',       '2.6.12'
gem 'facter',       '1.6.0'
gem 'rspec-puppet', '0.1.0'
gem 'rake',         '0.8.7'
{% endhighlight %}

Next we're going to add a couple of things to your `.gitignore`.

{% highlight text linenos %}
vendor/gems/
.bundle/
{% endhighlight %}

Now run we just need to tell bundler to install everything and commit our
changes to the repository.

{% highlight console linenos %}
$ bundle install --path vendor/gems
Fetching source index for http://rubygems.org/
Installing rake (0.8.7)
Installing diff-lcs (1.1.3)
Installing facter (1.6.0)
Installing puppet (2.6.12)
Installing rspec-core (2.7.1)
Installing rspec-expectations (2.7.0)
Installing rspec-mocks (2.7.0)
Installing rspec (2.7.0)
Installing rspec-puppet (0.1.0)
Using bundler (1.0.21)
Your bundle is complete! It was installed into ./vendor/gems
$ git add Gemfile
$ git add Gemfile.lock
$ git commit -a -m "Bundler setup for testing"
{% endhighlight %}

OK, time to configure [RSpec](https://www.relishapp.com/rspec).  Create
a `spec` directory in the root of your Puppet repository and create a file in
the `spec` folder called `spec_helper.rb`.  Adjust `c.module_path` and
`c.manifest_dir` to point to your modules and manifests directories in your
repository.

{% highlight ruby linenos %}
require 'rspec-puppet'

RSpec.configure do |c|
  c.module_path = "modules"
  c.manifest_dir = 'manifests'
end
{% endhighlight %}

The last thing we need to do is create a [Rake](http://rake.rubyforge.org) task
to run our tests.  Create a `Rakefile` in the root of your Puppet repository
with the following.

{% highlight ruby linenos %}
require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = 'modules/*/spec/*/*_spec.rb'
end

task :default => :test
{% endhighlight %}

## Testing your first function

For the sake of this example, let's create a simple module with a single
function (that I'm going to borrow from Puppet Lab's stdlib module).

{% highlight console linenos %}
$ mkdir -p modules/misc/lib/puppet/parser/functions
$ mkdir -p modules/spec/functions
{% endhighlight %}

Download [this
function](https://raw.github.com/puppetlabs/puppetlabs-stdlib/master/lib/puppet/parser/functions/bool2num.rb)
and drop it in `modules/misc/lib/puppet/parser/functions`.

Basically this function should

 * return 0 if you pass it 'f', 'false', 'n', 'no', 0, '', 'undef' or
   'undefined'.
 * return 1 if you pass it 't', 'true', 'y', 'yes' or 1.
 * raise Puppet::ParseError if you pass it anything else.

Before we continue, you should now go and read the [rspec-puppet
README](https://github.com/rodjek/rspec-puppet/blob/master/README.md).  The
tests for this function should live in `modules/misc/spec/functions/bool2num_spec.rb`.

{% highlight ruby linenos %}
require 'spec_helper'

describe 'bool2num' do
  it { should run.with_params('true').and_return(1) }
  it { should run.with_params('t').and_return(1) }
  it { should run.with_params('y').and_return(1) }
  it { should run.with_params('yes').and_return(1) }
  it { should run.with_params('1').and_return(1) }

  it { should run.with_params('false').and_return(0) }
  it { should run.with_params('f').and_return(0) }
  it { should run.with_params('n').and_return(0) }
  it { should run.with_params('no').and_return(0) }
  it { should run.with_params('0').and_return(0) }
  it { should run.with_params('undef').and_return(0) }
  it { should run.with_params('undefined').and_return(0) }
  it { should run.with_params('').and_return(0) }

  it { should run.with_params('foo').and_raise_error(Puppet::ParseError) }
end
{% endhighlight %}

Most of this should be pretty self explanatory, however there is a couple of
important things:

 * The `spec_helper.rb` required on line 1 is the `spec_helper.rb` in the
   `spec` directory at the root of your repository, not from the per-module
   `spec` directory.
 * The description on line 3 **must** be a string and it **must** be the name
   of the function that you are testing so that RSpec can set the subject
   correctly.

Now for the all important running of the tests.

{% highlight console linenos %}
$ rake
/usr/bin/ruby -S rspec modules/misc/spec/functions/bool2num_spec.rb
..............

Finished in 2.61 seconds
14 examples, 0 failures
{% endhighlight %}

Huzzah!  Now go and write tests for the rest of your functions.  In the next
article in this series, we'll cover how to test your Puppet manifests (`.pp`
files).
