use 5.010;
use strict;
use warnings;
use lib 'tlib';

use Test::More;
plan tests => 5;


# Extract and compile subunits from module's .pm file...
{
    package Basic::Subunit;
    use Test::Subunits 'Test::Module::Basic';
}

# Then use these subunit subroutines to run tests...

subtest def_count => sub {
    ok 'Basic::Subunit'->can('def_count') => 'subroutine defined';

    is Basic::Subunit::def_count(), 0 => 'called as expected';
    done_testing();
};


subtest normalize_list => sub {
    ok 'Basic::Subunit'->can('normalize_list') => 'subroutine defined';

    is_deeply Basic::Subunit::normalize_list([1,2,undef,3,undef,4]), [1..4] => 'called as expected';
    done_testing();
};

subtest normalize_count => sub {
    ok 'Basic::Subunit'->can('normalize_count');

    is Basic::Subunit::normalize_count(),   0 => 'called as expected (active)';
    is Basic::Subunit::normalize_count(+1), 1 => 'called as expected (passive)';
    done_testing();
};

subtest divide_list => sub {
    ok 'Basic::Subunit'->can('divide_list');

    my $result = Basic::Subunit::divide_list([1..5], 3);
    is_deeply $result->[0], [4..5] => 'in right';
    is_deeply $result->[1], [1..3] => 'out right';
    done_testing();
};

subtest report_rejections => sub {
    ok 'Basic::Subunit'->can('report_rejections');
    local *STDOUT;
    open *STDOUT, '>', \my $stdout;
    Basic::Subunit::report_rejections(3, (1,2) );
    is $stdout, "Rejected: 1 (<= 3)\nRejected: 2 (<= 3)\n" => 'right output';
    done_testing();
};

done_testing();

