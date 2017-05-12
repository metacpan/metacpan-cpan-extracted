#!perl

use strict;
use warnings;

use Test::More tests => 6 * 2;

my @comp = (0, 0);
my @exec = (0, 0);

my $rx;

{
 use re::engine::Plugin comp => sub { ++$comp[0] },
                        exec => sub { ++$exec[0]; 0 };

 eval '$rx = qr/foo/';
 is "@comp", '1 0', 'is compiled with the first engine';
 is "@exec", '0 0', 'not executed yet';
}

"abc" =~ /$rx/;
is "@comp", '1 0', 'was compiled with the first engine';
is "@exec", '1 0', 'is executed with the first engine';

{
 use re::engine::Plugin comp => sub { ++$comp[1] },
                        exec => sub { ++$exec[1]; 0 };

 "def" =~ /$rx/;
 is "@comp", '1 0', 'was still compiled with the first engine';
 is "@exec", '2 0', 'is executed with the first engine again';

 eval '$rx = qr/bar/';
 is "@comp", '1 1', 'is compiled with the second engine';
 is "@exec", '2 0', 'not executed since last time';
}

"ghi" =~ /$rx/;
is "@comp", '1 1', 'was compiled with the second engine';
is "@exec", '2 1', 'is executed with the second engine';

{
 use re 'debug';

 "jkl" =~ /$rx/;
 is "@comp", '1 1', 'was still compiled with the second engine';
 is "@exec", '2 2', 'is executed with the second engine again (and not with "re \'debug\'")';
}
