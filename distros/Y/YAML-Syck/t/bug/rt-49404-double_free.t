#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use YAML::Syck;

my $entry = { a => 'b' };
my $db = [ $entry, $entry ];

my $dump = Dump($db);
is( $dump, qq{--- \n- &1 \n  a: b\n- *1\n} );

my $dbcopy = Load($dump);
is_deeply( $dbcopy, $db );

$dbcopy->[1] = $dbcopy->[0];
my $dumpcopy = Dump($dbcopy);
is( $dump, qq{--- \n- &1 \n  a: b\n- *1\n} );

my $dbcopycopy = Load($dumpcopy);
is_deeply( $dbcopy, $db );

