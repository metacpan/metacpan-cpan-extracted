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


package Wizard::Elem::Text::HTML;

@Wizard::Elem::Text::HTML::ISA = qw(Wizard::Elem::HTML);
$Wizard::Elem::Text::HTML::VERSION = '0.01';


sub Display {
    my($self, $wiz, $form, $state) = @_;
    $self->SUPER::Display($wiz, $form, $state);
    my $attrstr = '';
    my $hurl = $form->HelpUrl() || 'gethelp.ep';
    my $mod = ref($state); $mod =~ s/\::/\//g; $mod .= '.pm';
    my $item = "item_" . $self->{'name'}; $item =~ s/\-/\_/g;
    foreach my $key (keys %$self) {
	my $keystr = $key; $keystr =~ tr/a-z/A-Z/;
	$attrstr .= ' ' . $keystr . '="' 
	         . HTML::Entities::encode_entities($self->{$key}) . '" '; 
    }


    $form->AddHTML('<tr><td>' . HTML::Entities::encode_entities($self->{'descr'})
		   . '</td><td><input ' . $attrstr . '></td><td><a href="'
		   . $hurl . '?module=' . URI::Escape::uri_escape($mod)
		   . '#' . URI::Escape::uri_escape($item) . '">Help'
		   . '</a></td></tr>');
}


1;
