---
title: puppet-lint 1.0.0
layout: post
categories:
 - puppet
 - puppet-lint
---

It's been a long time coming but I'm happy to announce the release of
puppet-lint 1.0.0!

Along with a bunch of bugfixes and a rewrite of most of the code, there's some
(hopefully) exciting new features in this release.

## Automatic fixing of errors

Previewed in the 0.4.0 pre-release, simple problems can now be automatically
fixed by puppet-lint (some problems require complex refactoring and so
puppet-lint won't attempt anything on your behalf).

In 1.0.0, problems detected by the following checks can be automatically fixed
by running puppet-lint with `--fix`:

 * `slash_comments`
 * `star_comments`
 * `unquoted_node_name`
 * `unquoted_resource_title`
 * `unquoted_file_mode`
 * `file_mode`
 * `ensure_not_symlink_target`
 * `double_quoted_strings`
 * `only_variable_string`
 * `variables_not_enclosed`
 * `quoted_booleans`
 * `hard_tabs`
 * `trailing_whitespace`
 * `arrow_alignment`

Complimentary to `--fix`, puppet-lint now has a `--only-checks` parameter that
you can pass a comma seperated list of checks that you want to run.  This works
great when doing an initial pass over your code to fix problems.  Let's say
that you just want to realign all your `=>`s, run `puppet-lint --fix
--only-checks arrow_alignment modules/`.

## Plugin system

From it's inception, puppet-lint has enforced the official [style
guide](https://docs.puppetlabs.com/guides/style_guide.html) and I've had to
turn down a lot of good ideas and contributions because they're not a part of
that guide. To that end, I've added a plugin system in 1.0.0 so that we can
add and distribute custom checks outside of the main code base.

My hope is that together as a community we can come up with some new checks and
influence new versions of the style guide.  I've written
a [tutorial](http://puppet-lint.com/developer/tutorial/) that steps through
how to write a basic check.  If you've got a good idea for a check but aren't
up to writing it yourself, create an issue in the puppet-lint repo with the
["new check" label](https://github.com/rodjek/puppet-lint/labels/new%20check)
and maybe someone else will be able to.

You can find the currently tiny list of [community
plugins here](http://puppet-lint.com/plugins/).  They're distributed as Ruby
Gems so you can easily install them however you're currently managing
puppet-lint (`gem`, `bundler`, etc).

## Control comments

A much requested feature, you can now disable tests via special comments in
your code.  Read more about it
[here](http://puppet-lint.com/controlcomments/).

## New checks

A couple of new checks have been added to core puppet-lint in 1.0.0.

 * `unquoted_node_name` - Checks for unquoted node names
 * `puppet_url_without_modules` - Checks for fileserver URLs without the
   modules mountpoint.

## What's gone

The `class_parameter_defaults` check has been removed. This check was based on
a misreading of the style guide.

For a more complete list of changes, I'd recommend reading [the
changelog.](http://puppet-lint.com/changelog/)
