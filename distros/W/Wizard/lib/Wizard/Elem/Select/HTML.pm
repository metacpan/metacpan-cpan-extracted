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


package Wizard::Elem::Select::HTML;

@Wizard::Elem::Select::HTML::ISA = qw(Wizard::Elem::HTML);
$Wizard::Elem::Select::HTML::VERSION = '0.01';


sub Display {
    my($self, $wiz, $form, $state) = @_;
    $self->SUPER::Display($wiz, $form, $state);
    my $options = $self->{'options'};
    my $name = $self->{'name'};
    my $value = $self->{'value'};

    $options = '' unless defined($options);
    $options = '' unless @$options;
    my $str = '<tr><td>' 
	     . HTML::Entities::encode_entities($self->{'descr'}) 
	. '</td>';
    unless (ref($options) eq 'ARRAY') {
	my $astr = $str . '<td>' . $options
	        . '<input type=hidden name="' . $name . '" value="'
		. HTML::Entities::encode_entities($options) . '"></td></tr>';
	return $form->AddHTML($astr);
    }
    $str .= '<td><SELECT NAME="' . $name . '">' . "\n";
    foreach my $opt (@$options) {
	$str .= '<option' . (($opt eq $value) ? ' SELECTED ' : '')  . '>' 
	      . HTML::Entities::encode_entities($opt) . "\n";
    }
    $str .= '</SELECT></td></tr>';
    $form->AddHTML($str);
}


1;

