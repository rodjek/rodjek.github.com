---
title: From Quick Hack To Serious Project
layout: post
categories:
 - puppet
 - puppet-lint
---

You might have noticed that there hasn't been a puppet-lint release in quite
some time and that I've become a bit lax when it comes to keeping up with bugs
and pull requests.

Puppet-lint originally started as something to fill in some time while
10,000 metres above the Tasman Sea and like all good hack projects, I kept
adding more and more code onto it to get each release out the door as quickly
as possible.  This lead to a number of questionable design decisions, the
biggest of which was using Puppet's lexer to tokenise the manifests that are
being analysed.

Don't get me wrong, the Puppet lexer is fantastic and I doubt I can
write a better one, but as it's a part of a separate active project, developing
against such a moving target results in constantly adding new corner cases with
every Puppet release.  This has resulted in a messy code base that I haven't
really desired to touch, to the detriment of the project.

## So what now?

If you've been following
[the project on GitHub](https://github.com/rodjek/puppet-lint/), you might have
noticed a flurry of recent activity in the
[dust\_bunny branch](https://github.com/rodjek/puppet-lint/compare/master...dust_bunny).
Over the last week, I made the call to rip out the Puppet lexer and replace it
with a simple one of my own.  Along with removing the constantly moving target,
it has had a couple of other major benefits:

 1. Faster start up time, as we're no longer loading Puppet.
 2. A custom lexer tailored to our needs means we can now access additional data
    that was previously discarded (like comments).

This has also given me an excuse to start a much needed cleanup of the code to
ensure that it is consistent and (hopefully) well documented.  Anyone who's
tried to add a new check will know what I mean.

## Great, why are you telling me?

While everything I've described doesn't sound very interesting from a features
point of view, it does represent a massive change to the internals of
puppet-lint and there's a very real possibility of introducing regressions.

So, what I need you to do is install the pre-release version of 0.2.0

    gem install puppet-lint -v 0.2.0.pre1 --pre

And then run it over your manifests.  If you run into any bugs, false positives
or negatives etc, please report them on the [project issue
tracker](https://github.com/rodjek/puppet-lint/issues) and tag them with the
dust\_bunny label.

Once any issues that have arisen as a result of these changes have been
resolved, I'll go back through the old issues and get them fixed up before
pushing out a proper 0.2.0 release with all the features you've been waiting
for.

## TL;DR
Lots of internal changes happened in puppet-lint recently and I need you to
help test it out and make sure no regressions have snuck in.

Install it, run it, report it. Ta!
