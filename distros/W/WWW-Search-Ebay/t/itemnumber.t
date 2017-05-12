
# $Id: itemnumber.t,v 1.15 2013-03-03 03:42:41 Martin Exp $

use Data::Dumper;
use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN {
  use_ok('WWW::Search::Ebay');
  } # end of BEGIN block

use strict;

my $iDebug;
my $iDump;

tm_new_engine('Ebay');

$iDebug = 0;
$iDump = 0;
TODO:
  {
  our $TODO = q{If you really need this functionality, notify the author};
  tm_run_test('normal', '140920371428', 1, 1, $iDebug, $iDump);
  }

__END__
