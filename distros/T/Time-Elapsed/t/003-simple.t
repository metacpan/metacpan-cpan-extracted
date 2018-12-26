#!/usr/bin/env perl -w
use strict;
use warnings;
use utf8;
use Test::More    qw( no_plan );
use Time::Elapsed qw( elapsed );
use constant TEST_STAMP_1 => 1_868_405;
use constant TEST_STAMP_2 => 1_868_401;
use constant UNICODE_PERL => 5.008;
use utf8;

if ( $] >= UNICODE_PERL ) {
   my $ok = eval q{ binmode Test::More->builder->output, ':utf8'; 1; };
}

# WEEK: 612886

# ---[ NORMAL ]--- #
ok( elapsed(TEST_STAMP_1) eq elapsed(TEST_STAMP_1, 'EN') , q{Test1 equals Test2} );

test( TEST_STAMP_1, __ => '21 days, 15 hours and 5 seconds'    );
test( TEST_STAMP_1, EN => '21 days, 15 hours and 5 seconds'    );
test( TEST_STAMP_1, TR => '21 gün, 15 saat ve 5 saniye'        );
test( TEST_STAMP_1, DE => '21 Tage, 15 Stunden und 5 Sekunden' );
test( TEST_STAMP_1, DA => '21 dage, 15 timer og 5 sekunder' );
test( TEST_STAMP_1, FR => '21 jours, 15 heures et 5 secondes' );

test( TEST_STAMP_2, __ => '21 days, 15 hours and 1 second'     );
test( TEST_STAMP_2, EN => '21 days, 15 hours and 1 second'     );
test( TEST_STAMP_2, TR => '21 gün, 15 saat ve 1 saniye'        );
test( TEST_STAMP_2, DE => '21 Tage, 15 Stunden und 1 Sekunde'  );
test( TEST_STAMP_2, DA => '21 dage, 15 timer og 1 sekund'  );
test( TEST_STAMP_2, FR => '21 jours, 15 heures et 1 seconde'  );

# ---[ UNDEF ]--- #
ok( ! defined( elapsed()      ), q{Parameter is undef} );
ok( ! defined( elapsed(undef) ), q{Parameter is undef} );

# ---[ FALSE ]--- #
_false( EN => 'zero seconds' );
_false( TR => 'sıfır saniye' );
_false( DE => 'Nullsekunden' );
_false( DA => 'nul sekunder' );
_false( FR => 'zéro seconde' );

sub _false {
   my $lang   = shift || 'EN';
   my $expect = shift;
   test(   0, $lang, $expect );
   test( q{}, $lang, $expect );
   ok( elapsed(0, $lang) eq elapsed(q{}, $lang) , q{Test1 equals Test2} );
   return;
}

sub test {
   my $num  = shift;
   my $lang = shift;
   my $want = shift;
   my $t    = elapsed( $num , $lang ne q{__} ? $lang : undef );
   ok( $t eq $want, qq{"$t" eq "$want"} );
   return;
}
