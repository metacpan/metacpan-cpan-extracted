#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More tests => 7;
use Tie::DiskUsage;

*_validate = \&Tie::DiskUsage::_validate;

{
    local $@;
    eval { _validate(undef, []) };
    ok(!$@, 'path is undef');
}

# possible formats of options
my @opts = (
    { val => undef,
      msg => 'option is undef'                  },
    { val => '',
      msg => 'option is empty'                  },
    { val => '-h',
      msg => 'short option'                     },
    { val => '--human-readable',
      msg => 'long option'                      },
    { val => '--max-depth=0',
      msg => 'long option with value assigned'  },
    { val => '--max-depth 0',
      msg => 'long option with separated value' },
);

my $tmpdir = tempdir();

foreach my $opt (@opts) {
    local $@;
    eval { _validate($tmpdir, [ $opt->{val} ]) };
    ok(!$@, $opt->{msg});
}
