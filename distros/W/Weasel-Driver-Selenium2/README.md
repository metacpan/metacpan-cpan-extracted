
# NAME

Weasel::Driver::Selenium2 - Selenium::Remote::Driver wrapper for Weasel

# VERSION

0.10

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

This module implements an extension to
[Weasel](https://github.com/perl-weasel/weasel/), which
implements the `Weasel::DriverRole` protocol.


# INSTALLATION

```sh
  # Install Weasel::Driver::Selenium2
  $ cpanm Weasel::Driver::Selenium2
```

# SUPPORT

## BUGS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel-driver-selenium2/issues

## DISCUSSION

Community support is available through
[perl-weasel@googlegroups.com](mailto:perl-weasel@googlegroups.com).

# COPYRIGHT

```
Copyright (c)  2016-2019  Erik Huelsmann
```

# LICENSE

Same as Perl
