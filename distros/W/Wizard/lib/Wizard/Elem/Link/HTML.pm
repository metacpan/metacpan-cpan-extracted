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


package Wizard::Elem::Link::HTML;

@Wizard::Elem::Link::HTML::ISA = qw(Wizard::Elem::HTML);
$Wizard::Elem::Link::HTML::VERSION = '0.01';


sub Display {
    my($self, $wiz, $form, $state) = @_;
    $self->SUPER::Display($wiz, $form, $state);
    my $value = $self->{'value'};
    unless($value) {
	my $hurl = $form->HelpUrl() || 'gethelp.ep';
	my $mod = ref($state);  my $item = $mod;
	my $action = $self->{'action'} || $wiz->Action(); 
	$action =~ s/\-/\_/g; $action =~ s/^Action\_//;
	$mod =~ s/\::/\//g; $mod .= '.pm';
	$item =~ s/^[^\:]\:://g; $item = $item . "_Menu";
	$value = $hurl . '?module=' . CGI->escape($mod)
	    . '#' . CGI->escape($action || $item); 
    }
    $form->AddHTML('<tr><td><a href="' . $value . '">' . HTML::Entities::encode_entities($self->{'descr'} || 'Help') . '</a></td></tr>'); 
}


1;
