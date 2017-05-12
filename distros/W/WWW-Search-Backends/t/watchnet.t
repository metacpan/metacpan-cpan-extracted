
# $Id: watchnet.t,v 1.3 2007/07/20 20:28:54 Daddy Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::WatchNet') };

use strict;

my $iDebug;
my $iDump = 0;

&tm_new_engine('WatchNet');
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 1-page query...");
$iDebug = 0;
$iDump = 0;
# This test returns one (long) page of results:
&tm_run_test_no_approx('normal', 'tissot', 111, undef, $iDebug, $iDump);
;

__END__

