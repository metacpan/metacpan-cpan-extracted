
# NAME

Weasel::Driver::Mock

# VERSION

0.01

# SYNOPSIS

```perl
  use Weasel;
  use Weasel::Session;
  use Weasel::Driver::Mock;

  my %opts = (
    states => [
       { cmd => 'get', args => [ 'http://localhost/index' ] },
       { cmd => 'find', args => [ '//div[@id="your-id"]' ] },
    ],
  );
  my $weasel = Weasel->new(
       default_session => 'default',
       sessions => {
          default => Weasel::Session->new(
            driver => Weasel::Driver::Mock->new(%opts),
          ),
       });

  $weasel->session->get('http://localhost/index');
```

# DESCRIPTION

This module implements the `Weasel::DriverRole`
API for [Weasel](https://github.com/perl-weasel/weasel/)
to simulate webpage interactions for testing purposes.

# INSTALLATION

```sh
  # Install Weasel::Driver::Mock
  $ cpanm Weasel::Driver::Mock
```

# SUPPORT

## BUGS

Bugs can be filed in the GitHub issue tracker for the
Weasel::Driver::Mock project:
 https://github.com/perl-weasel/weasel-driver-mock/issues

## DISCUSSION

Community support is available through
[perl-weasel@googlegroups.com](mailto:perl-weasel@googlegroups.com).

# COPYRIGHT

```
Copyright (c)  2019  Erik Huelsmann
```

# LICENSE

Same as Perl
