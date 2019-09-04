
# Test2::MojoX [![Build Status](https://api.travis-ci.com/elcamlost/Test2-MojoX.svg?branch=master)](https://travis-ci.com/elcamlost/Test2-MojoX) [![Coverage Status](https://coveralls.io/repos/github/elcamlost/Test2-MojoX/badge.svg)](https://coveralls.io/github/elcamlost/Test2-MojoX)

  Testing Mojo with Test2

```perl
use Test2::V0;
use Test2::MojoX;
use Mojolicious::Lite -signatures;
get '/' => sub {
  shift->render(
    json => {
      scalar => 'value',
      array  => [qw/item1 item2/],
      hash   => {key1 => 'value1', key2 => 'value2'}
    }
  );
};

my $t = Test2::MojoX->new;
$t->get_ok('/')->json_is(hash {
  field scalar => 'value';
  field array  => array {
    item 'item1';
    item 'item2';
    end;
  };
  field hash => hash {
    field key1 => 'value1';
    field key2 => 'value2';
    end;
  };
  end;
});

```

## Installation

Module available at [CPAN](https://metacpan.org/pod/Test2::MojoX). So you can install with your favourite cpan installer, such as cpan, carton, carmel etc.
