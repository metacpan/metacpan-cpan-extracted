#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.4 2003/10/22 21:06:10 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

@subscripts = qw(
		 autoscroll.pl
		);
print "1.." . scalar(@subscripts) . "\n";

foreach my $script (@subscripts) {
    my $path = "examples/" . $script;
    system($^X, "-Mblib", $path);
    $i++;
    if ($?) {
	print "not ";
    }
    print "ok $i\n";
}

__END__
