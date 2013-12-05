---
title: rspec-puppet 1.0.0
layout: post
categories:
 - puppet
 - rspec-puppet
---

It's been a while, but finally there's a new release of rspec-puppet.
Originally slated to be 0.2.0 but promoted to 1.0.0 due to a couple of
backwards incompatible changes.

## What might cause you problems
### create_resource matcher
This deprecated matcher has been removed entirely now.  If you still have code
using it, you should switch to using the generic `contain_<resource>` matcher
instead.

### include_class matcher
This matcher has now been deprecated and will be removed in the next major
release.  The reason this is on it's way out is that it doesn't support
parameterised classes and this has caused a lot of confusion for many users.

If you use `include_class` anywhere, you'll see the following depreciation
notice.

{% highlight text %}
DEPRECATION WARNING: you are using deprecated behaviour that will
be removed from a future version of RSpec.

* include_class is deprecated.
* please use contain_class instead.
{% endhighlight %}

So, change:

{% highlight ruby linenos %}
it { should include_class('foo') }
{% endhighlight %}

To:

{% highlight ruby linenos %}
it { should contain_class('foo') }
{% endhighlight %}

### Changes to how parameters are matched
In previous versions of rspec-puppet, parameter values were matched extremely
naively, where all values were flattened down to a string before comparison.
This means that `['b', 'ba']` would have been equal to `['bb', 'a']` for
example.  As of 1.0.0, this behaviour has changed and we now compare data
structures like arrays and hashes correctly, so you may have to adjust your
tests accordingly.

## What's new
### hiera support
Set the path to your `hiera.yaml` file in your `RSpec.configure` block and
you're good to go.

{% highlight ruby linenos %}
RSpec.configure do |c|
  # snip
  c.hiera_config = '/path/to/your/hiera.yaml'
end
{% endhighlight %}

### compile matcher
This new matcher should the be first thing in any rspec-puppet test suite.  It
checks that the catalogue will compile correctly and that there are no
dependency cycles in the generated graph.

{% highlight ruby linenos %}
it { should compile }
{% endhighlight %}

This matcher also has a chain method to enable checking that all dependencies
in the catalogue have been met - `with_all_deps`.

{% highlight ruby linenos %}
it { should compile.with_all_deps }
{% endhighlight %}

While at first glance, it might seem that this shouldn't be optional however
there are cases where you might not want to test this (if, for example, you are
testing a module that notifies a resource in a different module).

### relationship tests
Some new additions to the `contain_<resource>` matcher are the resource
relationship tests.

{% highlight ruby linenos %}
it { should contain_file('foo').that_requires('File[bar]') }
it { should contain_file('foo').that_comes_before('File[bar]') }
it { should contain_file('foo').that_notifies('Service[bar]') }
it { should contain_service('foo').that_subscribes_to('File[bar]') }
{% endhighlight %}

Regardless of how you define your relationships, either using the
metaparameters (`require`, `before`, `notify` and `subscribe`) or the chaining
arrows (`->`, `<-`, `~>` and `<~`) these tests will work.

Testing the reverse of the relationship described in your Puppet code will also
work with these new methods.  Take the following manifest for example:

{% highlight puppet linenos %}
notify { 'foo': }
notify { 'bar':
  before => Notify['foo'],
}
{% endhighlight %}

Both of the following tests will work:

{% highlight ruby linenos %}
it { should contain_notify('bar').that_comes_before('Notify[foo]') }
it { should contain_notify('foo').that_requires('Notify[bar]') }
{% endhighlight %}

### only_with tests
Also new to the `contain_<resource>` matcher are the `only_with` tests.  Unlike
the `with` tests which only test that the specified parameters have been
defined, `only_with` tests that these are the *only* parameters passed to
a resource.

Like the `with` tests, you can specify a single parameter with the
`only_with_<parameter>` method:

{% highlight ruby linenos %}
it { should contain_service('ntp').only_with_ensure('running') }
{% endhighlight %}

Or, you can pass it a hash of parameters and values:

{% highlight ruby linenos %}
it do
  should contain_service('ntp').only_with(
    'ensure' => 'running',
    'enable' => true,
  )
end
{% endhighlight %}

### resource counting matchers
The last new matchers for this release are `have_resource_count`,
`have_class_count` and the generic `have_<resource>_resource_count`.  As you
can guess, these matchers:

Count the total number of resources in the catalogue

{% highlight ruby linenos %}
it { should have_resource_count(3) }
{% endhighlight %}

Count the number of classes in the catalogue

{% highlight ruby linenos %}
it { should have_class_count(2) }
{% endhighlight %}

Count the number of resources of a particular type in the catalogue

{% highlight ruby linenos %}
it { should have_exec_resource_count(0) }
{% endhighlight %}

---

As always, if you find any bugs or have any suggestions for new functionality,
please create an issue [here](https://github.com/rodjek/rspec-puppet/issues).
