use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN { use_ok 'Test::Group::Foreach' }

sub e ($) {
    my $code = shift;
    eval $code;
    die $@ if $@;
}

lives_ok {e 'next_test_foreach(my $p, "p", 1)'       } "1 val pass";
lives_ok {e 'next_test_foreach(my $p, "p", 1, 2)'    } "2 vals pass";
lives_ok {e 'next_test_foreach(my $p, "p", 1, 2, 3)' } "3 vals pass";

dies_ok {e 'next_test_foreach()'          } "no args fail";
dies_ok {e 'next_test_foreach(my $q)'     } "one arg fail";
dies_ok {e 'next_test_foreach(my $q, "q")'} "two args fail";

lives_ok {e 'next_test_foreach my $p, "p", 1'       } "1 val pass proto";
lives_ok {e 'next_test_foreach my $p, "p", 1, 2'    } "2 vals pass proto";
lives_ok {e 'next_test_foreach my $p, "p", 1, 2, 3' } "3 vals pass proto";

dies_ok {e 'next_test_foreach'           } "no args fail proto";
dies_ok {e 'next_test_foreach my $q'     } "one arg fail proto";
dies_ok {e 'next_test_foreach my $q, "q"'} "two args fail proto";

dies_ok  {next_test_foreach(my $a, 'a', [])} "0elt arrayref arg fail";
dies_ok  {next_test_foreach(my $a, 'a', [1])} "1elt arrayref arg fail";
lives_ok {next_test_foreach(my $a, 'a', [1,2])} "2elt arrayref arg pass";
dies_ok  {next_test_foreach(my $a, 'a', [1,2,3])} "3elt arrayref arg fail";

