# Testing equivalent next_test_foreach call examples in the pod

use strict;
use warnings;

use Test::More tests => 4*6;
use Test::Builder::Tester;
use Pod::Snippets;

use Test::Group;
use Test::Group::Foreach;

my $snips = load Pod::Snippets(
    $INC{"Test/Group/Foreach.pm"}, '-markup' => "test"
);

Test::Group->verbose(2);

foreach my $i (1 .. 4) {
    my $code = $snips->named("equiv$i")->as_code;
    $code =~ s/my \$p/\$p/g or die "no 'my \$p' in [$code]";
    my $p;
    eval $code;
    diag "eval [$code]: $@" if $@;
    ok !$@, "equiv$i code runs";

    my @vals;
    test_out("ok 1 - mytest outer");
    test_diag(
        'Running group of tests - mytest outer',
        'ok 1.1 mytest inner (p=foo)',
        'ok 1.2 mytest inner (p=bar)',
        'ok 1.3 mytest inner (p=null)',
        'ok 1.4 mytest inner (p=long)',
    );
    test 'mytest outer' => sub {
        ok 1, 'mytest inner';
        push @vals, $p;
    };
    test_test("snippet $i output"); 

    is $vals[0], 'foo',      "snippet $i 1st val";
    is $vals[1], 'bar',      "snippet $i 2nd val";
    is $vals[2], "\0",       "snippet $i 3rd val";
    is $vals[3], 'foo'x1000, "snippet $i 4th val";
}

