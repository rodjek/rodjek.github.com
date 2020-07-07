---
title: Stop Writing Puppet Modules That Suck
layout: post
categories:
 - puppet
---

Whenever I need to setup a new service on one of my hosts, the first thing I do
is head to [the forge](https://forge.puppet.com) and
[GitHub](https://github.com) to try and find a decent Puppet module that
already exists for it.

I almost always leave in disappointment.

## Puppet modules are libraries

Much like `string.h` provides everything you need to manipulate strings in C,
your Puppet modules should provide everything needed to manage a service out of
the box.  By that I mean, I want to pull down your module to enable the
functionality I need in Puppet **without modifying your module at all**.

### Package, File, Service

Regrettably, most of the modules out there don't deviate from the basic
`package`, `file`, `service` model.

{% highlight puppet linenos %}
class ntp {
  package { 'ntp':
    ensure => installed,
  }

  file { '/etc/ntp.conf':
    ensure  => file,
    source  => 'puppet:///modules/ntp/etc/ntp.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => Package['ntp'],
    notify  => Service['ntp'],
  }

  service { 'ntp':
    ensure => 'running',
    enable => 'true',
  }
}
{% endhighlight %}

While this might be all you need in your homogeneous environment, it's
unlikely that this will work in someone elses environment without
modifications.  

### Package, File, Service, Facter

A common extension to this model is to add conditionals using Facter variables
to cover a set of different use cases (CentOS vs Debian, etc).

{% highlight puppet linenos %}
class ntp {
  case $::operatingsystem {
    Debian: {
      $packagename = 'openntp'
      $servicename = 'openntp'
    }
    default: {
      $packagename = 'ntp'
      $servicename = 'ntp'
    }
  }

  package { $packagename:
    ensure => installed,
  }

  file { '/etc/ntp.conf':
    ensure  => file,
    source  => 'puppet:///modules/ntp/etc/ntp.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => Package[$packagename],
    notify  => Service[$servicename],
  }

  service { $servicename:
    ensure => 'running',
    enable => true,
  }
}
{% endhighlight %}

While this is slightly more useful, it doesn't cover the possibility of wanting
to override a value on a per-host basis.

### Package, File, Service, Facter and... Global Variables?  Seriously?

If you ask most people for the "best practice" method of passing parameters to
their modules, they'll probably recommend using global variables - where you
set a variable in your node definition or ENC and it magically gets picked up
inside the various classes that you've included.

{% highlight puppet linenos %}
node 'foo.example.com' {
  $ntp_running = true
  $monitor = true
  $backup = true
  $fml = true

  include ntp
}

class ntp {
  # trimmed for brevity

  service { $servicename:
    ensure => $ntp_running ? {
      true  => 'running',
      false => 'stopped',
    },
  }
}
{% endhighlight %}

Do we really need to go into why this is a bad idea?  Puppet's variable scoping
is confusing enough on it's own.

## So what should you be doing

To put it simply, write your Puppet modules like you would write a library for
your favorite programming language.  Don't know a programming language?  You're
working towards the almighty "Infrastructure as Code" ideal.  Stop making
excuses like "I don't know how to program so I didn't know any better" and go
and learn a language.

 * Don't make your users edit your code to do the work they want.
 * Don't rely on global variables to pass information to your modules.
 * Make it easy for other people to add **features** to your module.

While it looks like the 3rd point contradicts the 1st point, it doesn't.
There's a big difference between someone sending you a patch to your module to
support a distro that it doesn't currently support and someone having to go and
edit a template inside your module in order to change a config value that you
didn't think anyone would need to change.

## An example of a good module

Take a look at the Puppet Labs [NTP
module](https://github.com/puppetlabs/puppetlabs-ntp/blob/master/manifests/init.pp).
It's not perfect, but it's pretty close.

First off, it's using a parameterised class, so there's no global variables
polluting the namespace while still allowing us to change the parameters used
to configure NTP without editing the module itself.  If you're using an older
version of Puppet that doesn't support parameterised classes, a defined type
will work just as well.

Secondly, it has support for a good number of different distributions *but* it
has a default case that causes Puppet to abort and let the user know that this
module isn't supported on their machine.  This is much better than just blindly
making changes to a system using values that may or may not work for it.

For the folks using ENCs that don't support parameterised classes or defined
types, you're still OK because you can just put this into your role definition
like so

{% highlight puppet linenos %}
class mycompany::role::frontend {
  class { 'ntp':
    servers => ['ntp.mycompany.com'],
  }
}
{% endhighlight %}

### How this module could be made even better

The addition of a  generic `ntp::config` type that used either Augeas or
parsedfile on the back end to set arbitrary configuration values, i.e.

{% highlight puppet linenos %}
class { 'ntp':
  servers => ['ntp.example.com'],
}

ntp::config {
  'statsdir':
    value => '/var/log/ntp';
  'statistics':
    value => 'rawstats';
}
{% endhighlight %}

Also, replacing the `autoupdate` parameter with a `version` parameter so that
it was possible to specify a particular package version, 'latest', 'installed'
etc. would be a great addition.

## That's all folks

How would you like to see modules written?  What currently annoys you about the
modules out there?  Do you disagree with everything I've written and want the
last 10 minutes of your life back?  Let me know.
