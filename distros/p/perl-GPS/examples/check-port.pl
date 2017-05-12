#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: check-port.pl,v 1.4 2007/05/24 19:22:59 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2005 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use strict;
use Getopt::Long;
use GPS::Garmin;

my $v = 0;
GetOptions("v+" => \$v)
    or die "usage: $0 [-v [-v ...]]";

my %ports = (BSD     => [ map { "/dev/cuaa$_" } 0 .. 3 ],
	     Linux   => [ map { ("/dev/ttyS$_",
				 "/dev/ttyUSB$_",
				)
			      } 0 .. 3 ],
	     Windows => [ map { "COM$_"       } 0 .. 3 ],
	    );

my @ports;
if ($^O eq 'MSWin32') {
    @ports = (map { @{ $ports{$_} } } qw(Windows));
} elsif ($^O =~ /bsd/i) {
    @ports = (map { @{ $ports{$_} } } qw(BSD Linux));
} else { # Linux, other Unices
    @ports = (map { @{ $ports{$_} } } qw(Linux BSD));
}

TRY: {
    for my $port (@ports) {
	warn "Try port $port...\n";
	my $gps = eval {
	    GPS::Garmin->new(Port => $port,
			     Baud => 9600,
			     timeout => 10,
			     verbose => $v,
			    );
	};
	if ($gps) {
	    warn "Success with port $port!\n";
	    warn "The product id is: " . $gps->product_id . "\n";
	    last TRY;
	} elsif ($@ && $v >= 2) {
	    warn $@;
	}
    }
    warn "No success!\n";
}

__END__
