# -*- perl -*-

#
# $Id: WinPrint.pm,v 1.3 2004/03/20 20:41:46 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999,2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Tk::WinPrint;
#use strict;
use vars qw($VERSION);
$VERSION = '0.05';
use base qw(DynaLoader Tk::Canvas); # XXX why DynaLoader????

bootstrap Tk::WinPrint 800.024; #$VERSION;

*{"Tk::Canvas::print"} = sub { my $c = shift;
			       $c->PrintCanvasCmd($c,@_);
			   };

1;

__END__
