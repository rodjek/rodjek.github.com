---
title: Fix Simple Problems With puppet-lint
layout: post
categories:
 - puppet
 - puppet-lint
---

Since the first release of puppet-lint, one of the top two feature requests has
been the ability to automatically fix trivial style issues (detecting problems
is all well and good but no one wants to manually fix the eleventy thousand
problems that have accumulated over the years).

To that end, I have just shipped a beta release of puppet-lint (0.4.0.pre1)
which includes the experimental fixing support!  I highly encourage everyone to
give it a try and report any issues they find.

Currently, puppet-lint supports fixing a limited subset of detectable problems.
There will probably be more added to this list over time however some problems
will always require a human to decide how to proceed.

At this time, puppet-lint do the following for you:

 * Converting `//` comments into `#` comments.
 * Quoting unquoted resource titles.
 * Quoting unquoted file mode strings.
 * Converting 3 digit octal file modes into 4 digit modes.
 * Converting double quoted strings without variables into single quoted
   strings.
 * Converting double quoted strings that only contain a variable into an
   unquoted variable.
 * Enclosing variables in double quoted strings that haven't been enclosed in
   braces.
 * Unquoting quoted boolean values.
 * Converting hard tabs into 2 space soft tabs.
 * Removing trailing whitespace.
 * Fixing arrow (`=>`) alignment in resources and hashes.

# Caveat Emptor

**Running puppet-lint with fix mode enabled is a potentially destructive
action.**

I'm going to assume that your manifests are stored in some sort of version
control and that you're comfortable discarding the changes puppet-lint makes if
you don't like them.

# Trying it out

First of all install the new version, either with RubyGems:

{% highlight console linenos %}
gem install --pre puppet-lint -v 0.4.0.pre1
{% endhighlight %}

or Bundler:

{% highlight ruby linenos %}
gem 'puppet-lint', '0.4.0.pre1'
{% endhighlight %}

Then just call puppet-lint with the `-f` or `--fix` option

{% highlight console linenos %}
$ puppet-lint -f test.pp
FIXED: double quoted string containing no variables on line 1
FIXED: string containing only a variable on line 3
FIXED: indentation of => is not properly aligned on line 5
FIXED: unquoted file mode on line 5
FIXED: mode should be represented as a 4 digit octal value or symbolic mode on line 5
{% endhighlight %}

And the diff of the changes to my test file is

{% highlight diff linenos %}
diff --git a/test.pp b/test.pp
index 7cd1e93..4d455cf 100644
--- a/test.pp
+++ b/test.pp
@@ -1,6 +1,6 @@
-$foo = "/tmp/foo"
+$foo = '/tmp/foo'

-file { "$foo":
+file { $foo:
   ensure => present,
-  mode => 444,
+  mode   => '0444',
 }
{% endhighlight %}

So, please try it out and [create an issue on the
repository](https://github.com/rodjek/puppet-lint/issues/) if you run into any
problems!
