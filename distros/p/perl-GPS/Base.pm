# -*- perl -*-

#
# $Id: Base.pm,v 1.4 2006/09/09 16:57:15 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2003 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package GPS::Base;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

# Factory
sub new {
    my($class, %param) = @_;
    if ($param{Protocol} eq 'GRMN') {
	require GPS::Garmin;
	GPS::Garmin->new(%param);
    } elsif ($param{Protocol} eq 'NMEA') {
	require GPS::NMEA;
	GPS::NMEA->new(%param);
    } else {
	die "Unknown or unspecified Protocol: $param{Protocol}";
    }
}

sub common_new {
    my $type = shift;
    my %param = @_;
    my $port = $param{'Port'} ||
	($^O eq 'MSWin32'
	 ? 'COM1'
	 : ($^O =~ /^(?:(?:free|net|open)bsd|bsd(?:os|i))$/
	    ? (-e '/dev/cuad0'
	       ? '/dev/cuad0' # FreeBSD 6.x and later
	       : '/dev/cuaa0'
	      )
	    : '/dev/ttyS1'
	   )
	);
    my $baud = $param{'Baud'} || 9600;
    my $protocol = $param{'Protocol'} || 'GRMN';
    my $timeout = $param{'timeout'} || 10;

    my $self = bless
    {	'port'	     =>	 $port,
	'baud'	     =>	 $baud,
	'protocol'   =>	 $protocol,
	'timeout'    =>	 $timeout,
	'verbose'    =>	 $param{verbose},
	(exists $param{'Return'} && $param{'Return'} eq 'hash'
	 ? (return_as_hash => 1)
	 : ()
	),
    }, $type;

    $self->connect unless $param{do_not_init};

    $self;
}

1;

__END__
