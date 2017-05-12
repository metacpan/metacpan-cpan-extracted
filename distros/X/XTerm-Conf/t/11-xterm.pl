#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 11-xterm.pl,v 1.1 2008/10/01 21:22:11 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2008 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use FindBin;
use blib "$FindBin::RealBin/..";
use XTerm::Conf qw(xterm_conf xterm_conf_string);
use Test::More qw(no_plan);

my $file = shift;

print STDERR "Does it hang? --- Should finish after 5 seconds!\n";
eval {
    xterm_conf(-title => "Does it hang?");
    is(xterm_conf_string(-report => 'title'), "Does it hang?\n", "report does not hang");
};
my $err = $@;

__END__
