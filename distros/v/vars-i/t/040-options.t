# -*- perl -*-

# t/040-options.t - tests related to options (which are not yet implemented!)

use strict;
use warnings;
use lib::relative '.';
use Kit;

use vars::i;     # Fatal if we can't load

test_arrayref_to_vars_i();
test_hashref_to_vars_i();
test_option_in_hashref();
test_option_in_arrayref();

done_testing();

# --- The tests ----------------------------------------------------------

sub test_arrayref_to_vars_i {   # A sanity check
    eval_lives_ok q[{
        package MY::TestArrayRefToVarsI;
        use vars::i [
            '$answer' => 42,
            '$string' => 'Hello',
        ];
    }], 'use vars::i [...]';
    eval_is_var '$MY::TestArrayRefToVarsI::answer', 42;
    eval_is_var '$MY::TestArrayRefToVarsI::string', 'Hello';
} #test_arrayref_to_vars_i

sub test_hashref_to_vars_i {    # Same as arrayref, but a hashref
    eval_lives_ok q[{
        package MY::TestHashRefToVarsI;
        use vars::i +{
            '$answer' => 43,
            '$string' => 'Hello!',
        };
    }], 'use vars::i HASHREF';
    eval_is_var '$MY::TestHashRefToVarsI::answer', 43;
    eval_is_var '$MY::TestHashRefToVarsI::string', 'Hello!';
} #test_hashref_to_vars_i

sub test_option_in_hashref {
    eval_dies_like q[{
        package MY::TestOptionInHashref;
        use vars::i +{
            '-NONEXISTENT_OPTION' => 'value',
            '$answer' => 43,
            '$string' => 'Hello!',
        };
    }], qr/option/;
} #test_option_in_hashref

sub test_option_in_arrayref {
    eval_dies_like q[{
        package MY::TestOptionInArrayref;
        use vars::i [
            '-NONEXISTENT_OPTION' => 'value',
            '$answer' => 43,
            '$string' => 'Hello!',
        ];
    }], qr/option/;
} #test_option_in_arrayref

