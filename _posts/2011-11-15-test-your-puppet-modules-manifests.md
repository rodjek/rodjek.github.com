---
layout: post
title: Test Your Puppet Modules - Manifests
categories:
 - puppet
 - rspec
 - testing
published: false
---

Continuing on from [last
time](https://bombasticmonkey.com/2011/11/04/test-your-puppet-modules-functions),
you should now have a [rspec-puppet](https://github.com/rodjek/rspec-puppet/)
testing environment setup in your Puppet repository and be well on your way to
having unit tests for all your custom Puppet functions.

Lets move on to testing the meat of your Puppet module, the manifests.

## What are we trying to achieve?

Writing tests for your manifests might seem like a massive duplication of
effort now, but later on it's going to save you a lot of hassle.

An easily detectable problem that is tripping up a lot of people who are upgrading from
2.6 to 2.7 is that dashes (-) are now allowed in variable names, so
`$var-my-string` is no longer evaluated as `$var + '-my-string'`, it's now one
giant variable name `$var-my-string`, which for most people becomes an empty
string, causing a lot of unexpected behavior.

## Testing your first class

rspec-puppet expects to find tests for your Puppet classes in a particular
folder (namely `modules/<module>/spec/classes`).  The reason for this is so
that it can automatically detect that you're wanting to test a Puppet class and
make certain custom matchers available to you and generally make the whole
process a lot less painful.

{% highlight console linenos %}
$ mkdir -p modules/sysctl/spec/classes
$ mkdir modules/sysctl/manifests
{% endhighlight %}

Now, we need a class to test, so create `modules/sysctl/manifests/common.pp` and
paste in the following

{% highlight puppet linenos %}
class sysctl::common {
  exec { 'sysctl/reload':
    command     => '/sbin/sysctl -p /etc/sysctl.conf',
    refreshonly => true,
    returns     => [0, 2],
  }
}
{% endhighlight %}

Pretty basic class and easy to test.  Time to write some tests, so open up
`modules/sysctl/spec/classes/common_spec.rb` and add the following

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl::common' do
end
{% endhighlight %}

Much like the test we wrote previously for our Puppet functions, the tests for
classes (and defines) have the same basic structure.  On line 1 you require the
`spec_helper.rb` file we created in the previous post and on line 3 we specify
the name of the class that we want to test as a **string**.

If you're one of those silly people who use global variables to pass
parameters to your classes, you can put a block of Puppet code defining those
variables in a `pre_condition` helper method that returns a **string** like so

{% highlight ruby linenos %}
require 'spec_helper'

describe 'my::class' do
  let(:pre_condition) { "
    $var1 = 'foo'
    $var2 = 'bar'
  " }
end
{% endhighlight %}

Similarly, if you have a parameterised class, you can specify the parameters to
pass to your class by defining a `params` helper method that returns a **hash**
containing your parameters

{% highlight ruby linenos %}
require 'spec_helper'

describe 'my::class' do
  let(:params) {
    {
      :foo => 'bar',
      :baz => 'gronk',
    }
  }
end
{% endhighlight %}

We don't need any of that for this class however.  All we want to do is test
that including this class will create an `exec` resource with the specified
parameters.  We can do this using the generic `create_<resource>` matcher
provided by rspec-puppet (now would be a good time to refresh yourselves with
the contents of [rspec-puppet's
README](https://github.com/rodjek/rspec-puppet/blob/master/README.md))

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl::common' do
  it { should contain_exec('sysctl/reload') \
    .with_command('/sbin/sysctl -p /etc/sysctl.conf') \
    .with_refreshonly(true) \
    .with_returns([0, 2]) }
end
{% endhighlight %}

You could say testing this class is a bit pointless as it contains a single
static resource and maybe it is, it's up to you.

## Testing your first defined type

Let's move on to testing something slightly more interesting.  First of all, we
need our defined type to test.  Drop the following in
`modules/sysctl/manifests/init.pp`

{% highlight puppet linenos %}
define sysctl($value) {
  include sysctl::common

  augeas { "sysctl/${name}":
    context => '/files/etc/sysctl.conf',
    changes => "set ${name} '${value}'",
    onlyif  => "match ${name}[.='${value}'] size == 0",
    notify  => Exec['sysctl/reload'],
  }
}
{% endhighlight %}

We'll also need a directory to store the specs for our defines.  rspec-puppet
expects to find them in `modules/<module>/spec/defines`, so go ahead and create
that now

{% highlight console linenos %}
$ mkdir modules/sysctl/spec/defines
{% endhighlight %}

As mentioned previously, tests for defined types have exactly the same basic
layout as tests for classes and functions, so we'll start off by putting that
in our spec file (`modules/sysctl/spec/defines/sysctl_spec.rb`).  As before, we
specify the name of our defined type as a **string** in the top level
`describe` block.

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl' do
end
{% endhighlight %}

Before we can start writing any test cases, we need to specify the title of
the `sysctl` instance we're testing and supply it a parameter.

You can specify the title by defining a `title` helper method that returns
a string containing the title

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl' do
  let(:title) { 'vm.swappiness' }
end
{% endhighlight %}

Parameters are specified exactly the same for defined types as they are for
classes, by defining a `params` helper method that returns a **hash**
containing the parameters.

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl' do
  let(:title) { 'vm.swappiness' }
  let(:params) { {:value => '60' } }
end
{% endhighlight %}

Now we're ready to do some testing!  First thing we want to test is that the
`sysctl::common` class gets included, which we can do using the `include_class`
matcher

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl' do
  let(:title) { 'vm.swappiness' }
  let(:params) { {:value => '60'} }

  it { should include_class('sysctl::common') }
end
{% endhighlight %}

Next we want to test that an `augeas` resource get created with the correct
parameters for our inputs, which we do with the same `create_<resource>`
matcher that we used earlier in the test for the `sysctl::common` class.

{% highlight ruby linenos %}
require 'spec_helper'

describe 'sysctl' do
  let(:title) { 'vm.swappiness' }
  let(:params) { {:value => '60'} }

  it { should include_class('sysctl::common') }
  it { should contain_augeas('sysctl/vm.swappiness') \
    .with_context('/files/etc/sysctl.conf') \
    .with_changes("set vm.swappiness '60'") \
    .with_onlyif("match vm.swappiness[.='60'] size == 0") \
    .with_notify('Exec[sysctl/reload]') }
end
{% endhighlight %}

Let's run those tests.

{% highlight console linenos %}
$ bundle exec rake
/usr/bin/ruby -S rspec modules/misc/spec/functions/bool2num_spec.rb
modules/sysctl/spec/classes/common_spec.rb
modules/sysctl/spec/defines/sysctl_spec.rb
.................

Finished in 0.46194 seconds
17 examples, 0 failures
{% endhighlight %}

Excellent!
