---
title: Distributing Augeas lenses with Puppet's pluginsync
layout: post
categories:
- puppet
- augeas
---

Sick of having to write `file` resources to distribute the Augeas lenses that
your module depends on?  Why not use Puppet's pluginsync functionality to
distribute them with the rest of your module?

Under your module's `lib` directory, create the following directory structure

    modules/<module>/lib/
                         augeas/
                                lenses/

Your module should now look like this:

    modules/<module>/manifests/
                     templates/
                     lib/
                         puppet/
                         facter/
                         augeas/
                                lenses/

Drop your Augeas lenses into this `lenses` directory and Puppet will 
distribute them to all your clients automatically.  Now we just need to tell
Augeas where to find these lenses.

The easiest way to go about this is to set a default `load_path` value for
Augeas type.  To do that, add the following to your `site.pp`.

{% highlight ruby linenos %}
Augeas {
  load_path => "/usr/share/augeas/lenses:${settings::vardir}/augeas/lenses",
}
{% endhighlight %}

Note: Puppet will display an error for each lens during runs as it'll try to
load them as Ruby files.  It's noisy, but it's not a fatal error.  I'm hoping
to find an easy way to prevent this.
