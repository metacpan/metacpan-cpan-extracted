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

package Wizard::Form::HTML;

@Wizard::Form::HTML::ISA = qw(Wizard::Form);

sub Display {
    my($self, $wiz, $state) = @_;
    $self->ResetHTML();
    $self->AddHTML('<table>');
    my $table_finished=0;
    $self->{'objects'} = {};
    $wiz->{'ep'}->{'_ep_wizard_form'} = $self;
    foreach my $elem (@{$self->{'elems'}}) {
	if((ref($elem) =~ /Submit\:\:/) && (!($table_finished))) {
	    $table_finished = 1;
	    $self->AddHTML('</table>') ;
	}
	$elem->Display($wiz, $self, $state);
    }
}

sub ResetHTML { shift->{'html-' . (shift || 'body')} = '';};

sub HelpUrl {
    my $self = shift;
    $self->{'help_url'} = shift if @_;
    $self->{'help_url'};
}

sub AddHTML {
    my $self = shift; my $htmlout = shift;
    my $part = shift || 'body';
    $self->{'html-' . $part} .= "$htmlout\n";
}

sub object {
    my $self = shift; my $o = $self->{'objects'};
    my $name = shift; 
    return (keys %$o) if wantarray && !$name;
    if(@_) {
	my $obj = shift; 
	$name ||= $obj->{'name'};
	unless($name) {
	    my $pre = ref($obj); my $num = 0;
	    $pre = $2 if($pre =~ /^([^\:]+\:\:)*([^\:]+)\:\:HTML$/);
	    while(exists($o->{$pre. '_' . (++$num)})) {};
	    $name = $pre . '_' . $num;
	    $obj->{'name'} = $name;
	}
	$o->{$name} = $obj;
    }
    $o->{$name};
}



