
# $Id: timezone.t,v 1.2 2007/07/20 20:35:30 Daddy Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More skip_all;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Timezone') };

use strict;

my $iDebug;
my $iDump = 0;

&tm_new_engine('Timezone');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 1-page queries...");
$iDebug = 2;
$iDump = 0;
# This test returns one page of results:
&tm_run_test_no_approx('normal', 'tisot', 1, 222, $iDebug, $iDump);
# goto SKIP_MULTI;

;
MULTI_RESULT:
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns several of pages of results:
&tm_run_test_no_approx('normal', 'tissot', 501, undef, $iDebug, $iDump);
SKIP_MULTI:
;

__END__

