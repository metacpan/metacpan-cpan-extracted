#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: nowarn.t,v 1.2 2008/09/23 19:33:44 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::Date;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # skip tests only work with installed Test module\n";
	CORE::exit;
    }
}

my $mw;
BEGIN {
    if (!eval { $mw = tkinit }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

BEGIN { plan tests => 1 }

my $date=$mw->Date(
	-datefmt => "%2m/%2d/%4y",
	-timefmt => "%2H:%2M:%2S",
	-editable=>0,
	-value=>'now')->pack;

my $timer;
$timer = $date->repeat(1000, [sub {
				  if (Tk::Exists($date)) {
				      $date->configure(-value => 'now');
				  } else {
				      $timer->cancel;
				  }
			      }]);
$mw->update;
ok(1);

__END__
