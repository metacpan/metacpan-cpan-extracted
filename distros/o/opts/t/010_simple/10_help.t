use strict;
use warnings;
use opts;
use Test::More;

eval {
        @ARGV = qw(--help);
        foo();
};

is $@, <<EOS, 'help message';
usage: t/010_simple/10_help.t [options]

options:
   -p, --pi, -q                    
   -r, --radius   Radius of circle 
   -h, --help     This help message

EOS

done_testing;


sub foo {
    opts my $pi => { isa => 'Num', alias => 'q' },
         my $radius => { isa => 'Num', comment => 'radius of circle' };
    is $pi, 3.14;
}
