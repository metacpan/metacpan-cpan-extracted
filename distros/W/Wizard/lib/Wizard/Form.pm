# -*- perl -*-
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@ispsoft.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   $Id$
#

use strict;


package Wizard::Form;

sub new {
    my $proto = shift;  my $wiz = shift;
    my $extension = $proto;
    $extension =~ s/.*\:\://;
    my $self = { @_ };
    bless($self, (ref($proto) || $proto));
    @{$self->{'elems'}} = map {
	if (ref($_) eq 'ARRAY') {
	    my $c = shift @$_;
	    $c .= "::$extension";
	    my $c_class = $c;
	    $c_class =~ s/\:\:/\//g;
	    require "$c_class.pm";
	    $c->new($self, @$_);
	} else {
	    $_;
	}
    } @{$self->{'elems'}};
    $self;
}


1;
