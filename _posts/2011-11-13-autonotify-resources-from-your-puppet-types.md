---
title: Auto-notify Resources From Your Puppet Types
layout: post
categories:
 - puppet
---

So, I ran into a bit of a problem yesterday.  I was working on a Puppet
module for the [Sensu](https://github.com/sonian/sensu/) monitoring framework,
part of which involved writing a custom Puppet type to manage the configuration
of service checks.  Normally this is a trivial matter, however in this case,
the checks must be configured on both the server **and** the client and must
therefore be able to notify either the server process or the client process or
both to restart after a configuration change.

Obviously, I couldn't just do this:

{% highlight puppet linenos %}
sensu_check { 'mycheck':
  notify => [
    Service['sensu-client'],
    Service['sensu-server'],
  ],
}
{% endhighlight %}

As if the host was only running the client process, this would result in an
error during the Puppet runs.

One option would be to use the following mess:

{% highlight puppet linenos %}
if(defined(Service['sensu-client']) && defined(Service['sensu-server'])) {
  Sensu_check {
    notify => [
      Service['sensu-client'],
      Service['sensu-server'],
    ],
  }
} elsif defined(Service['sensu-client']) {
  Sensu_check {
    notify => Service['sensu-client'],
  }
} else {
  Sensu_check {
    notify => Service['sensu-server'],
  }
}
{% endhighlight %}

Not the most elegant solution in the world.  Ideally what I needed was
something like the existing `autorequire` functionality that creates `require`
relationships between your custom type and the named resources automatically
but only if the resources exist in the node catalogue.

Unfortunately, such functionality doesn't exist (yet), so I had to go some
digging around in Puppet's codebase to implement it.  The first thing to do was
to establish a way to create arbitrary `notify` relationships.  This turned out
to be easily done:

{% highlight ruby linenos %}
Puppet::Type.newtype(:mytype) do
  def initialize(*args)
    super
    self[:notify] = [
      "Service[myservice]",
      "Service[myotherservice]",
    ]
  end
end
{% endhighlight %}

Now, all I needed to do was make it so that it only notified the resources that
actually existed in the node's manifest

{% highlight ruby linenos %}
Puppet::Type.newtype(:mytype) do
  def initialize(*args)
    super
    self[:notify] = [
      "Service[myservice]",
      "Service[myotherservice]",
    ].select { |ref| catalog.resource(ref) }
  end
end
{% endhighlight %}

The moral of this extremely drawn out story?  Anything is possible in Puppet if
you're willing to get your hands dirty.  And this should really be a built in
feature \*hint\*.
