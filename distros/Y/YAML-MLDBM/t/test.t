BEGIN { $^W = 1 }
use strict;
use Test::More tests => 1;
use YAML::MLDBM;

my $h = YAML::MLDBM->new('./my_dbm_file');

my $s = { foo => [ 24..42 ],
          bar => { 'a'..'z' }
        };

$h->{baz} = $s;

is_deeply($h->{baz}, $s);
