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

use Wizard::Elem::HTML ();


package Wizard::Elem::TextArea::HTML;

@Wizard::Elem::TextArea::HTML::ISA = qw(Wizard::Elem::HTML);
$Wizard::Elem::TextArea::HTML::VERSION = '0.01';


sub Display {
    my($self, $wiz, $form, $state) = @_;
    $self->SUPER::Display($wiz, $form, $state);
    my $value = defined($self->{'value'}) ? $self->{'value'} : '';
    $form->addHTML(sprintf('<tr><td>%s</td><td><textarea name="%s">%s'
			   . '</textarea></td></tr>',
			   HTML::Entities::encode_entities($self->{'descr'}),
			   $self->{'name'},
			   HTML::Entities::encode_entities($value)));
}


1;
