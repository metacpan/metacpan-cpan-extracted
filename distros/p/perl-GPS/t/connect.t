#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: connect.t,v 1.4 2006/11/26 08:14:40 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use GPS::Garmin;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

eval {
    my $gps = GPS::Garmin->new(timeout => 1);
};
my $error = $@;
ok($error eq '' || $error =~ /(timed out|can't open|permission denied|Operation not supported)/i, "Timeout of device, no permission to port or no error")
    or diag $error;

__END__
