use 5.010;
use strict;
use warnings;
use lib 'tlib';

use Test::More;
plan tests => 3;


# This module uses the abbreviated <wrapper> <params> mechanism...
use Test::Subunits 'Test::Module::HalfWrappers';

# Now test that it built wrappers subs that return their own parameters...

subtest normalize_list => sub {
    ok 'main'->can('normalize_list') => 'subroutine defined';

    is_deeply normalize_list([1,2,undef,3,undef,4]), [1..4] => 'called as expected';
    done_testing();
};

subtest normalize_count => sub {
    ok 'main'->can('normalize_count');

    is normalize_count(),   0 => 'called as expected (active)';
    is normalize_count(+1), 1 => 'called as expected (passive)';
    done_testing();
};

subtest report_rejections => sub {
    ok 'main'->can('report_rejections');
    local *STDOUT;
    open *STDOUT, '>', \my $stdout;
    my @retval = report_rejections(3, (1,2) );
    is_deeply \@retval, [3, (1,2) ]                        => 'got expected return value';
    is $stdout, "Rejected: 1 (<= 3)\nRejected: 2 (<= 3)\n" => 'got right output';
    done_testing();
};

done_testing();


