#! perl

use strict;
use warnings;

use Text::Template::LocalVars qw[ fill_in_string ];
use Test::More;

Text::Template::LocalVars->always_prepend( q[ use Test::More; ] );

sub broken { my %args = @_; die $args{error}; }

subtest 'trackvarpkg on' => sub {

    # this test nests a bunch of fragments and checks that each
    # nested fragment environment gets cloned from the one above it.

    # compiled into this package, so parent tracking has to work
    # for this to work correctly.
    {
        package TP_ON1;
        use Text::Template::LocalVars qw[ fill_in_string ];
        use Test::More;


        # if true, localize the template variables in the nested fill.
        # used to check that the parent environment has not (or has)
        # been changed.
        our $localize;

        # keep track of how deep the call stack is so we can stop the
        # test
        our $maxdepth = 5;
        our $depth;

        # this is what is monitored for correctness;
        our $counter;

        # recursive checks. increment counter each time
        # check is called (by itself) and compare that to
        # the depth of calls. this ensures we're seeing the
        # correct parent.
        sub check {

            return if ++$depth > $maxdepth;

            my $passed = shift;
            my $ldepth = $depth;

            is( $passed, $ldepth, "($ldepth) counter == depth" );

            fill_in_string(
                q[ { my $lcounter = ++$counter ;
                     TP_ON1::check( $counter );
                     if ( $TP_ON1::localize ) {
                         is( $counter, $lcounter, "($lcounter) no change to fragment env after fill" )
                     }
                     else {
                         is( $counter, $TP_ON1::maxdepth+1,
                             "($lcounter) fragment env changed after fill" );
                     }
                   } ],
                localize    => $localize,
                trackvarpkg => 1,
                broken      => \&::broken
            );

            # after the nested fills finish, this package's $counter
            # should be untouched.
            is( $counter, undef,
                "($ldepth) counter untouched after nested fill_in" );
        }
    }

    # this drives the code above
    {
        package TP_ON2;
        use Text::Template::LocalVars qw[ fill_in_string ];
        use Test::More;

        our $counter = 'SpecialMagicValue';

        subtest 'localized fill' => sub {

            $TP_ON1::depth    = -1;
            $TP_ON1::localize = 1;

            fill_in_string(
                q[ {  TP_ON1::check( $counter ); } ],
                hash   => { counter => 0 },
                broken => \&::broken,
            );

            is( $counter, 0,
                "initial counter set, but not touched after all of the fills" );

        };

        subtest 'non-localized fill' => sub {

            $TP_ON1::depth    = -1;
            $TP_ON1::localize = 0;

            $counter = 0;
            fill_in_string(
                q[ { TP_ON1::check( $a ); } ],
                hash   => { a => 0 },
                broken => \&::broken,
            );

            is(
                $counter,
                $TP_ON1::maxdepth + 1,
                "initial counter changed after all of the fills"
            );
        };

    }

};

subtest 'trackvarpkg off' => sub {

    # check that without trackvarpkg the default package is the
    # enclosing one
    subtest 'default package localization;' => sub {

        package TP_OFF1;
        use Text::Template::LocalVars qw[ fill_in_string ];
        use Test::More;

        our $a = 'TP_OFF1';
        fill_in_string(
            q[ { is( $a, 'TP_OFF1', "got value from default package"); $a .= 'X'; } ],
            localize    => 1,
            trackvarpkg => 0,
            broken      => \&broken
        );

        is( $a, 'TP_OFF1', "value untouched in package after nested fill_in" );

    };

    subtest 'nested fragments' => sub {
        {
            package TP_OFF2_1;
            use Text::Template::LocalVars;
            use Test::More;

            our $a = 'TP_OFF2_1';

	    # this will be called from within a template fragment in another
	    # package. check that this package is used by fill_in
            sub check {

                my $tpl = q[
               { is( $a, 'TP_OFF2_1', "nested value from code in other package (TP_OFF2_1)");
                     $a .= 'X';
               } ];

                Text::Template::LocalVars->new(
                    type   => 'string',
                    source => $tpl,
                    broken => \&::broken
                  )->fill_in(
                    localize    => 1,
                    trackvarpkg => 0,
                  );

                is( $TP_OFF2_1::a, 'TP_OFF2_1',
                    "value untouched in package after nested(1) fill_in (TP_OFF2_1)"
                );

            }

        }

        {
            package TP_OFF2_2;
            use Text::Template::LocalVars qw[ fill_in_string ];
            use Test::More;

            our $a = 'TP_OFF2_2';
            fill_in_string(
                q[
               { is( $a, 'TP_OFF2_2', "got value from default package (TP_OFF2_2)"); $a .= 'X'; }
               { fill_in_string(
                   q[{ is( $a, 'TP_OFF2_2X', "nested value from inline code: TP_OFF2_2X" );
                       $a .= 'X';
                     }],
                   localize => 1, trackvarpkg => 0,
                   broken => \&::broken,
                 );
               }
               { TP_OFF2_1::check(); }
               { is( $a, 'TP_OFF2_2X', "value ok after nested(2) fill"); $a .= 'X' }

            ],
                localize    => 1,
                trackvarpkg => 0,
                broken      => \&::broken
            );

            is( $TP_OFF2_2::a, 'TP_OFF2_2',
                "value untouched in package after nested(1) fill_in" );
        }
    };

};

done_testing;
