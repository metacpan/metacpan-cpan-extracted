#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Cwd;

BEGIN {
    my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir($cwd, 't/tlib');
}

use Test::More tests => 40;

local $SIG{__WARN__} = sub { BAIL_OUT( $_[0] ) };

no warnings 'once';


eval q{
    use maybe 'maybe::Test1';
};
is( $@, '',                                              'use maybe "maybe::Test1" succeed' );
ok( maybe->HAVE_MAYBE_TEST1,                             'maybe->HAVE_MAYBE_TEST1 is true' );
isnt( $INC{'maybe/Test1.pm'}, undef,                     '%INC for maybe/Test1.pm is set' );
is( maybe::Test1->VERSION, 123,                          'maybe::Test1->VERSION == 123' );
is( $maybe::Test1::is_ok, 1,                             '$maybe::Test1::is_ok == 1' );

eval q{
    use maybe 'maybe::Test2';
};
is( $@, '',                                              'use maybe "maybe::Test2" succeed' );
ok( maybe->HAVE_MAYBE_TEST2,                             'maybe->HAVE_MAYBE_TEST2 is true' );
isnt( $INC{'maybe/Test2.pm'}, undef,                     '%INC for maybe/Test2.pm is set' );
is( maybe::Test2->VERSION, undef,                        'maybe::Test2->VERSION is undef' );
is( $maybe::Test2::is_ok, 1,                             '$maybe::Test2::is_ok == 1' );

eval q{
    use maybe 'maybe::Test3';
};
is( $@, '',                                              'use maybe "maybe::Test3" succeed' );
ok( maybe->HAVE_MAYBE_TEST3,                             'maybe->HAVE_MAYBE_TEST3 is true' );
isnt( $INC{'maybe/Test3.pm'}, undef,                     '%INC for maybe/Test3.pm is set' );
is( maybe::Test3->VERSION, 123,                          'maybe::Test3->VERSION == 123' );
is( $maybe::Test3::is_ok, 0,                             '$maybe::Test3::is_ok == 0' );

eval q{
    use maybe 'maybe::Test4';
};
is( $@, '',                                              'use maybe "maybe::Test4" succeed' );
ok( ! maybe->HAVE_MAYBE_TEST4,                           'maybe->HAVE_MAYBE_TEST4 is false' );
is( $INC{'maybe/Test4.pm'}, undef,                       '%INC for maybe/Test4.pm is undef' );
is( maybe::Test4->VERSION, 123,                          'maybe::Test4->VERSION == 123' );
is( $maybe::Test4::is_ok, 0,                             '$maybe::Test4::is_ok == 0' );

eval q{
    use maybe 'maybe::Test6';
};
is( $@, '',                                              'use maybe "maybe::Test6" succeed' );
ok( maybe->HAVE_MAYBE_TEST6,                             'maybe->HAVE_MAYBE_TEST6 is true' );
isnt( $INC{'maybe/Test6.pm'}, undef,                     '%INC for maybe/Test6.pm is set' );
is( maybe::Test6->VERSION, 0,                            'maybe::Test6->VERSION == 0' );
is( $maybe::Test6::is_ok, 1,                             '$maybe::Test6::is_ok == 1' );

eval q{
    use maybe 'maybe::Test0';
};
is( $@, '',                                              'use maybe "maybe::Test0" succeed' );
ok( ! maybe->HAVE_MAYBE_TEST0,                           'maybe->HAVE_MAYBE_TEST0 is false' );
is( $INC{'maybe/Test0.pm'}, undef,                       '%INC for maybe/Test0.pm is undef' );
is( maybe::Test0->VERSION, undef,                        'maybe::Test0->VERSION is undef' );
is( $maybe::Test0::is_ok, undef,                         '$maybe::Test0::is_ok is undef' );

eval q{
    use maybe 'maybe::Test1';
};
is( $@, '',                                              'use maybe "maybe::Test1" succeed [2]' );
ok( maybe->HAVE_MAYBE_TEST1,                             'maybe->HAVE_MAYBE_TEST1 is true [2]' );
isnt( $INC{'maybe/Test1.pm'}, undef,                     '%INC for maybe/Test1.pm is set [2]' );
is( maybe::Test1->VERSION, 123,                          'maybe::Test1->VERSION == 123 [2]' );
is( $maybe::Test1::is_ok, 1,                             '$maybe::Test1::is_ok == 1 [2]' );

eval q{
    use maybe 'maybe::Test4';
};
is( $@, '',                                              'use maybe "maybe::Test4" succeed [2]' );
ok( ! maybe->HAVE_MAYBE_TEST4,                           'maybe->HAVE_MAYBE_TEST4 is false [2]' );
is( $INC{'maybe/Test4.pm'}, undef,                       '%INC for maybe/Test4.pm is undef [2]' );
is( maybe::Test4->VERSION, 123,                          'maybe::Test4->VERSION == 123 [2]' );
is( $maybe::Test4::is_ok, 0,                             '$maybe::Test4::is_ok == 0 [2]' );
