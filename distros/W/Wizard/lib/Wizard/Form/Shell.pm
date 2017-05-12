# -*- perl -*-
#
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

use strict;

use Wizard::Form ();


package Wizard::Form::Shell;

@Wizard::Form::Shell::ISA = qw(Wizard::Form);


sub Display {
    my($self, $wiz, $state) = @_;
    $self->{'options'} = {};
    $wiz->ResetParam();
    foreach my $elem (@{$self->{'elems'}}) {
	$elem->Display($wiz, $self, $state);
    }
    my $var;
    if (keys %{$self->{'options'}} == 1) {
	$var = (keys %{$self->{'options'}})[0];
    } else {
	while (1) {
	    print "\nSelect an option: ";
	    $var = <STDIN>;
	    chomp $var;
	    last if exists($self->{'options'}->{$var});
	}
    }
    my $val = $self->{'options'}->{$var};
    if (defined($val)) {
	$wiz->param($val, $var);
    } else {
	 $state->Running(0);
    }
}

sub Option {
    my($self, $id, $action) = @_;
    $self->{'options'}->{$id} = $action;
}

sub print { shift; print @_; }
sub printf { shift; printf(@_); }
sub readline { <STDIN> }

1;
