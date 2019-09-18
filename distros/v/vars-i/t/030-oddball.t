# -*- perl -*-

# t/030-oddball.t - tests of various edge conditions.  Mostly for coverage.
package MY::Oddball;

use lib::relative '.';
use Kit;

use vars::i;     # Fatal if we can't load

test_no_value_provided();
test_arrayref_value();
test_hashref_value();
test_inject_var();

done_testing();

# --- The tests ----------------------------------------------------------

sub test_no_value_provided{
    eval q[{
        package MY::Test1;
        use vars::i '$VAR';     # no value
        use vars::i '$WITH_VALUE', 42;
    }];
    is($@, '', 'Compiles `use` without value OK ');

    # A sanity check.  Note: `package` is required since `use strict`
    # always permits package-qualified names.
    my $val = eval q[do { package MY::Test1; use strict; $WITH_VALUE }];
    is($@, '', 'Can access variable in package');
    ok($val == 42, 'Variable value was set correctly');

    # Now make sure the use..'$VAR' line had no effect
    eval q[{
        package MY::Test1;
        use strict; no warnings 'all';
        $VAR;   # Shouldn't exist
    }];
    ok($@, '`use` without value did not create var');
} #test_no_value_provided()

sub test_arrayref_value {
    eval q[{
        package MY::Test2;
        use vars::i [
            '@VAR' => [1..3],
        ];
    }];
    is($@, '', 'Created @VAR ok');

    my @val = eval q[do { package MY::Test2; use strict; @VAR }];
    is($@, '', 'Can access @VAR');
    is($val[$_-1], $_, "val $_ OK") for 1..3;

} #test_arrayref_value()

sub test_hashref_value {
    eval q[{
        package MY::Test3;
        use vars::i [
            '%VAR' => {1..4},
        ];
    }];
    is($@, '', 'Created %VAR ok');

    my %val = eval q[do { package MY::Test3; use strict; %VAR }];
    is($@, '', 'Can access %VAR');
    is($val{$_}, $_+1, "val $_ OK") for (1,3);
} #test_hashref_value()

sub test_inject_var {
    eval q[{
        package MY::Test4;
        use vars::i '$MY::Oddball::InjectedVar' => 42;
    }];
    is($@, '', 'Created InjectedVar OK');

    my $val = eval '$InjectedVar';
    is($@, '', 'Can access InjectedVar');
    is($val, 42, 'InjectedVar set OK');
} #test_inject_var()
