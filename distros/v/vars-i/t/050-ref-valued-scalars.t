# -*- perl -*-

# t/050-ref-valued-scalars.t - tests of $=>[] and $=>{}

use strict;
use warnings;
use lib::relative '.';
use Kit;

use vars::i;     # Fatal if we can't load

# Sanity checks
test_plain_scalar();
test_plain_arrayref();
test_plain_array();

# Tests of ref-valued scalars
test_arrayref_in_scalar();
test_hashref();

done_testing();

# --- Sanity checks ------------------------------------------------------
# Compare these to the tests below.

sub test_plain_scalar {
    eval_lives_ok q[{
        package MY::TestPlainScalar;
        use vars::i '$answer' => 42;
    }], '$=>scalar';
    eval_is_var '$MY::TestPlainScalar::answer', '42';
} #test_plain_scalar

sub test_plain_arrayref {
    eval_lives_ok q[{
        package MY::TestPlainArrayRef;
        use vars::i '@one' => [1,2,3];
    }], '@=>arrayref';
    my $val =
        eval q[use strict; no warnings 'all'; scalar @MY::TestPlainArrayRef::one];
    is $@, '', '@one access';
    cmp_ok $val, '==', 3, 'scalar @one';

    foreach(0..2) {
        my $val = eval qq[use strict; no warnings 'all';
            \$MY::TestPlainArrayRef::one[$_]
        ];
        is $@, '', "...one[$_] access";
        cmp_ok $val, '==', $_+1, "MY::TestPlainArrayRef::one[$_]";
    }

} #test_plain_arrayref

sub test_plain_array {
    eval_lives_ok q[{
        package MY::TestPlainArray;
        use vars::i '@one' => 4, 5, 6;  # No arrayref
    }], '@=>array';
    my $val =
        eval q[use strict; no warnings 'all'; scalar @MY::TestPlainArray::one];
    is $@, '', '@one access';
    cmp_ok $val, '==', 3, 'scalar @one';

    foreach(0..2) {
        my $val = eval qq[use strict; no warnings 'all';
            \$MY::TestPlainArray::one[$_]
        ];
        is $@, '', "...one[$_] access";
        cmp_ok $val, '==', $_+4, "MY::TestPlainArray::one[$_]";
    }

} #test_plain_array

# --- The tests ----------------------------------------------------------

sub test_arrayref_in_scalar {
    eval_lives_ok q[{
        package MY::TestARInScalar;
        use vars::i '$one' => [7,8,9];
    }], '$=>arrayref';
    my $val =
        eval q[use strict; no warnings 'all'; scalar @$MY::TestARInScalar::one];
    is $@, '', '@$one access';
    cmp_ok $val, '==', 3, 'scalar @one';

    foreach(0..2) {
        my $val = eval qq[use strict; no warnings 'all';
            \$MY::TestARInScalar::one->[$_]
        ];
        is $@, '', "...one->[$_] access";
        cmp_ok $val, '==', $_+7, "\$MY::TestARInScalar::one->[$_]";
    }

} #test_arrayref_in_scalar

sub test_hashref {
    eval_lives_ok line_mark_string(
    q[{
        package MY::TestHashRef;
        use vars::i '$one' => {a=>1, b=>2};
    }]), '$=>hashref';
    my $val = eval line_mark_string(
        q[use strict; no warnings 'all';
            scalar keys %{$MY::TestHashRef::one}]);
    is $@, '', '%one access';
    cmp_ok $val, '==', 2, 'scalar keys %one';

    my %expect = (a=>1, b=>2);
    while(my ($k, $v) = each %expect) {
        my $val = eval line_mark_string(
            qq[use strict; no warnings 'all';
            \$MY::TestHashRef::one->{'$k'}
        ]);
        is $@, '', "...one->{$k} access";
        cmp_ok $val, '==', $v, "MY::TestHashRef::one->{$k}";
    }

} #test_hashref

