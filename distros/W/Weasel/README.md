

# NAME

Weasel - Perl's php/Mink-inspired abstracted web-driver framework

# VERSION

0.24

# SYNOPSIS

```perl
  use Weasel;
  use Weasel::Session;
  use Weasel::Driver::Selenium2;

  my $weasel = Weasel->new(
       default_session => 'default',
       sessions => {
          default => Weasel::Session->new(
            driver => Weasel::Driver::Selenium2->new(%opts),
          ),
       });

  $weasel->session->get('http://localhost/index');
```

# DESCRIPTION

This module abstracts away the differences between the various
web-driver protocols, like the Mink project does for PHP.

While heavily inspired by Mink, `Weasel` aims to improve over it
by being extensible, providing not just access to the underlying
browser, yet to provide building blocks for further development
and abstraction.

[Pherkin::Extension::Weasel](https://github.com/perl-weasel/pherkin-extension-weasel)
provides integration with
[Test::BDD::Cucumber](https://github.com/pjlsergeant/test-bdd-cucumber-perl)
(aka pherkin), for BDD testing.

For the actual page interaction, this module needs a driver to
be installed.  Currently, that means
[Weasel::Driver::Selenium2](https://github.com/perl-weasel/weasel-driver-selenium2).
Other driver implementations, such as [Sahi](http://sahipro.com/)
can be independently developed and uploaded to CPAN, or contributed.
(We welcome and encourage both!)


## DIFFERENCES WITH OTHER FRAMEWORKS


### Mnemonics for element lookup patterns

The central registry of xpath expressions to find common page elements
helps to keep page access code clean. E.g. compare:

```perl
   use Weasel::FindExpanders::HTML;
   $session->page->find('*contains', text => 'Some text');
```

With

```perl
   $session->page->find(".//*[contains(.,'Some text')]
                              [not(.//*[contains(.,'Some text')])]");
```

Multiple patterns can be registered for a single mnemonic. These
which be concatenated into a single xpath expression. This concatenated
expression allows to efficiently find matching elemnets with a single
driver query.

Besides good performance, this has the benefit that the following

```perl
   $session->page->find('*button', text => 'Click!');
```

can be easily extended to match
[Dojo toolkit's](http://dojotoolkit.org/documentation/) buttons as well
as regular buttens. The problem with Dojo's buttons is that their DOM
tree doesn't actually contain (visible) BUTTON or INPUT tags. To load
support for Dojo widgets, simply:

```perl
   use Weasel::Widgets::Dojo;
```

### Widgets encapsulate specific behaviours

All elements in `Weasel` are of the base type `Weasel::Element`, which
encapsulates the regular element interactions (click, find children, etc).

While most elements will be represented by `Weasel::Element`, it's possible
to implement other wrappers.  These offer a logical extension point to
implement tag-specific utility functions.  E.g.
`Weasel::Widgets::HTML::Select`, which adds the utility function
`select_option`.

These widgets also offer a good way to override default behaviours.  One
such case is the Dojo implementation of a `select` element.  This element
replaces the select tag entirely and in contrast with the original, doesn't
keep the options as child elements of the `select`-replacing tag.  By using
the Dojo widget library

```perl
   use Weasel::Widget::Dojo;
```

the lack of the parent/child relation between the the select and its options
is transparently handled by overriding the widget's `find` and `find_all`
methods.

# INSTALLATION

```sh
  # Install Weasel
  $ cpanm Weasel

  # Install Weasel's web driver
  $ cpanm Weasel::Driver::Selenium2
```

If you want to use Weasel's support for Dojo-widget interaction, also:

```sh
  $ cpanm Weasel::Widgets::Dojo
```

If you want to use Weasel with its Pherkin (BDD) integration, also:

```sh
  $ cpanm Pherkin::Extension::Weasel
```

# SUPPORT

## BUGS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel/issues

## DISCUSSION

Community support is available through
[perl-weasel@googlegroups.com](mailto:perl-weasel@googlegroups.com).

Chat support is available in the
[#perl-weasel:matrix.org](https://vector.im/beta/#/room/#perl-weasel:matrix.org)
channel

# COPYRIGHT

```
Copyright (c)  2016-2019  Erik Huelsmann
```

# LICENSE

Same as Perl
