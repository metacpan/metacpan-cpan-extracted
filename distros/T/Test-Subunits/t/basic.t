use 5.010;
use strict;
use warnings;
use lib 'tlib';

use Test::More;
plan tests => 5;


# Extract and compile subunits from module's .pm file...
use Test::Subunits 'Test::Module::Basic';

# Then use these subunit subroutines to run tests...

subtest def_count => sub {
    ok 'main'->can('def_count') => 'subroutine defined';

    is def_count(), 0 => 'called as expected';
    done_testing();
};


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

subtest divide_list => sub {
    ok 'main'->can('divide_list');

    my $result = divide_list([1..5], 3);
    is_deeply $result->[0], [4..5] => 'in right';
    is_deeply $result->[1], [1..3] => 'out right';
    done_testing();
};

subtest report_rejections => sub {
    ok 'main'->can('report_rejections');
    local *STDOUT;
    open *STDOUT, '>', \my $stdout;
    report_rejections(3, (1,2) );
    is $stdout, "Rejected: 1 (<= 3)\nRejected: 2 (<= 3)\n" => 'right output';
    done_testing();
};

done_testing();
