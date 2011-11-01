---
title: Augeas Won't Eat Your Children
layout: post
published: false
---

Augeas is an oft-overlooked tool when it comes to creating custom Puppet types.
Say you want to create a type to manage
[ssmtp's configuration file](http://linux.die.net/man/5/ssmtp.conf).  If you
posted to puppet-dev asking for help, you'd probably get 15 responses for how
to do it using parsedfile, but no mention of Augeas.  Let's fix that.

## What is Augeas?

[Augeas](http://augeas.net/) is a configuration editing tool that takes native
configuration files, turns them into a tree which can be manipulated as desired
before saving the tree back into the native file format.

For example, let's take the following example ini file that lives at
`/etc/my.ini`.

{% highlight ini %}
[section]
key = value
{% endhighlight %}

The tree that Augeas generates for this file looks like

{% highlight xquery %}
/files/etc/my.ini/section/key = "value"
{% endhighlight %}

Let's make a simple update to the file by adding a new section with a new value

{% highlight sh %}
set /files/etc/my.ini/foo/bar "baz"
save
{% endhighlight %}

The resulting file now looks like this

{% highlight ini %}
[section]
key = value

[foo]
bar = baz
{% endhighlight %}

## Installing Augeas

Chances are you've already installed Augeas as one of Puppet's dependencies.

If not, you can install it on OSX via homebrew, `brew install augeas`.

Most linux distibutions also have packages built for augeas as well.

## Meet ssmtp.conf

On to our example.  We're going to write a simple type to manage the contents
of ssmtp.conf as described by its
[man page](http://linux.die.net/man/5/ssmtp.conf).  It's a simple `key=value`
format, like this

{% highlight ini %}
#
# /etc/ssmtp.conf -- a config file for sSMTP sendmail.
#
# The person who gets all mail for userids < 1000
root=postmaster
# The place where the mail goes. The actual machine name is required
# no MX records are consulted. Commonly mailhosts are named mail.domain.com
# The example will fit if you are in domain.com and you mailhub is so named.
mailhub=mail
# Where will the mail seem to come from?
#rewriteDomain=localhost.localdomain
# The full hostname
hostname=localhost.localdomain
{% endhighlight %}

## Skeleton lens

Augeas knows how to parse configuration files through user defined "lenses".
These lenses typically live in `/usr/share/augeas/lenses`.

Let's start with a basic skeleton lens

{% highlight text %}
module Ssmtp =
  autoload xfm

  <the rest of the lens will go here>

  let filter = (incl "/etc/ssmtp/ssmtp.conf")

  let xfm = transform lns filter
{% endhighlight %}



## Complete lens

## Puppet Type

## Provider

## This looks like a hell of a lot of work compared to parsedfile

You're right, you could probably implement this example in far less code, but
say you wanted to manage the contents of a more complex file, like [hosts.allow](),
or [httpd.conf]()?  Be prepared to waste a lot of time fiddling with regexes
getting everything working with parsedfile.
