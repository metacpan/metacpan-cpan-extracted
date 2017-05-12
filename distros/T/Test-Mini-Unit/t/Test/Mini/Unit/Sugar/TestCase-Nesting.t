use Test::Mini::Unit;

# The following test cases will not actually be run.
# They are solely for demonstration.

case Top {
    our $super = shift(our @ISA);
    sub super   { $super }
    sub package { __PACKAGE__ }

    # Simple nesting
    case Nested {
        our $super = shift(our @ISA);
        sub super   { $super }
        sub package { __PACKAGE__ }

        case Deeply {
            our $super = shift(our @ISA);
            sub super   { $super }
            sub package { __PACKAGE__ }
        }
    }

    # Compound nesting
    case Sub::Package {
        our $super = shift(our @ISA);
        sub super   { $super }
        sub package { __PACKAGE__ }

        case Nested {
            our $super = shift(our @ISA);
            sub super   { $super }
            sub package { __PACKAGE__ }
        }
    }

    # Namespace qualification
    case ::Not::Nested {
        our $super = shift(our @ISA);
        sub super   { $super }
        sub package { __PACKAGE__ }

        case Deeply {
            our $super = shift(our @ISA);
            sub super   { $super }
            sub package { __PACKAGE__ }
        }
    }
}

{
    package Non::Test;
    use Test::Mini::Unit;
    
    case Case {
        our $super = shift(our @ISA);
        sub super   { $super }
        sub package { __PACKAGE__ }
    }
}

# Begin actual tests
####################
package t::Test::Mini::Unit::Sugar::TestCase::Nesting;
use base 'Test::Mini::TestCase';

use Test::Mini::Assertions;

sub assert_case {
    my ($pkg, $super) = @_;
    assert($pkg->can('package'));
    assert_equal($pkg->package(), $pkg);
    assert_equal($pkg->super(), $super);
}

sub test_top_level_cases {
    assert_case('Top', 'Test::Mini::TestCase');
}

sub test_simply_nested_cases {
    assert_case('Top::Nested', 'Top');
}

sub test_deeply_nested_cases {
    assert_case('Top::Nested::Deeply', 'Top::Nested');
}

sub test_compound_nested_cases {
    assert_case('Top::Sub::Package', 'Top');
}

sub test_nesting_beneath_compound_cases {
    assert_case('Top::Sub::Package::Nested', 'Top::Sub::Package');
}

sub test_qualified_cases {
    assert_case('Not::Nested', 'Top');
}

sub test_nesting_beneath_qualified_cases {
    assert_case('Not::Nested::Deeply', 'Not::Nested');
}

sub test_cases_under_non_testcase_namespaces {
    assert_case('Non::Test::Case', 'Test::Mini::TestCase');
}

1;
