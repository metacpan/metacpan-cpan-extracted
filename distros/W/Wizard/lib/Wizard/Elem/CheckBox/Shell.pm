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

use Wizard::Elem::Shell ();


package Wizard::Elem::CheckBox::Shell;

@Wizard::Elem::CheckBox::Shell::ISA = qw(Wizard::Elem::Shell);
$Wizard::Elem::CheckBox::Shell::VERSION = '0.01';


sub Display {
    my($self, $wiz, $form, $state) = @_;
    $self->{'default'} ||= 'no';
    my $val = defined($self->{'value'}) ? $self->{'value'} : $self->{'default'};
    $form->print("$self->{'descr'} (yes/no, default is no) [$val]: ");
    my $reply = $form->readline();
    chomp $reply;
    $reply = $val unless (($reply eq 'yes') || 
			  ($reply eq 'no'));
    $reply = ($reply eq 'yes') ? 'yes' : '';
    return $wiz->param($self->{'name'}, $reply);
}


1;
