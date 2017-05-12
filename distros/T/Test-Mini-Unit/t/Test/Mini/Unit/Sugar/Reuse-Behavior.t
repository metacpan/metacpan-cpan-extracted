use Test::Mini::Unit;

{
    no strict 'refs';

    package Deeply::Nested::Package::A;
    BEGIN { $INC{'Deeply/Nested/Package/A.pm'} = __FILE__ }
    sub import { push @{caller() . "::used"}, \@_ }

    package Deeply::Nested::A;
    BEGIN { $INC{'Deeply/Nested/A.pm'} = __FILE__ }
    sub import { push @{caller() . "::used"}, \@_ }

    package Deeply::Nested::B;
    BEGIN { $INC{'Deeply/Nested/B.pm'} = __FILE__ }
    sub import { push @{caller() . "::used"}, \@_ }

    package Deeply::C;
    BEGIN { $INC{'Deeply/C.pm'} = __FILE__ }
    sub import { push @{caller() . "::used"}, \@_ }

    package D;
    BEGIN { $INC{'D.pm'} = __FILE__ }
    sub import { push @{caller() . "::used"}, \@_ }
}

{
    package Deeply::Nested::Package;
    use Test::Mini::Unit::Sugar::Reuse;

    our @used = ();

    reuse A;
    reuse Package::A;
    reuse Nested::Package::A;
    reuse Deeply::Nested::Package::A;
    reuse ::Deeply::Nested::Package::A;

    reuse Nested::A;
    reuse Deeply::Nested::A;
    reuse ::Deeply::Nested::A;

    reuse B;
    reuse Nested::B;
    reuse Deeply::Nested::B;
    reuse ::Deeply::Nested::B;

    reuse C;
    reuse Deeply::C;
    reuse ::Deeply::C;

    reuse D;
    reuse ::D;
}

{
    package main;
    use Test::Mini::Unit::Sugar::Reuse;

    our @used = ();
    
    reuse Deeply::Nested::Package::A;
    reuse ::Deeply::Nested::Package::A;
    
    reuse Deeply::Nested::A;
    reuse ::Deeply::Nested::A;

    reuse Deeply::Nested::B;
    reuse ::Deeply::Nested::B;
    
    reuse Deeply::C;
    reuse ::Deeply::C;
    
    reuse D;
    reuse ::D;
}

case t::Test::Mini::Unit::Sugar::Reuse::Behavior {
    test deeply_nested_package_includes_as_expected {
        assert_equal(
            \@Deeply::Nested::Package::used,
            [
                [ 'Deeply::Nested::Package::A' ],
                [ 'Deeply::Nested::Package::A' ],
                [ 'Deeply::Nested::Package::A' ],
                [ 'Deeply::Nested::Package::A' ],
                [ 'Deeply::Nested::Package::A' ],

                [ 'Deeply::Nested::A' ],
                [ 'Deeply::Nested::A' ],
                [ 'Deeply::Nested::A' ],

                [ 'Deeply::Nested::B' ],
                [ 'Deeply::Nested::B' ],
                [ 'Deeply::Nested::B' ],
                [ 'Deeply::Nested::B' ],

                [ 'Deeply::C' ],
                [ 'Deeply::C' ],
                [ 'Deeply::C' ],

                [ 'D' ],
                [ 'D' ],
            ],
        );
    }

    test main_package_includes_as_expected {
        assert_equal(
            \@main::used,
            [
                [ 'Deeply::Nested::Package::A' ],
                [ 'Deeply::Nested::Package::A' ],

                [ 'Deeply::Nested::A' ],
                [ 'Deeply::Nested::A' ],

                [ 'Deeply::Nested::B' ],
                [ 'Deeply::Nested::B' ],

                [ 'Deeply::C' ],
                [ 'Deeply::C' ],

                [ 'D' ],
                [ 'D' ],
            ],
        );
    }
}
