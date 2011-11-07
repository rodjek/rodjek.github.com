---
layout: post
title: Test Your Puppet Modules - Manifests
---

Continuing on from [last
time](http://bombasticmonkey.com/2011/11/04/test-your-puppet-modules-functions),
you should now have a [rspec-puppet](https://github.com/rodjek/rspec-puppet/)
testing environment setup in your Puppet repository and be well on your way to
having unit tests for all your custom Puppet functions.

Lets move on to testing the meat of your Puppet module, the manifests.

## What are we trying to achieve?

## Testing your first class

rspec-puppet expects to find tests for your Puppet classes in a particular
folder (namely `modules/<module>/spec/classes`).  The reason for this is so
that it can automatically detect that you're wanting to test a Puppet class and
make certain custom matchers available to you and generally make the whole
process a lot less painful.

{% highlight console linenos %}
$ mkdir -p modules/sysctl/spec/classes
$ mkdri modules/sysctl/manifests
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

## Testing your first defined type
