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


package Wizard::Elem::Select::Shell;

@Wizard::Elem::Select::Shell::ISA = qw(Wizard::Elem::Shell);
$Wizard::Elem::Select::Shell::VERSION = '0.01';


sub Display {
    my($self, $wiz, $form, $state) = @_;
    my $options = $self->{'options'};
    my $value = $self->{'value'};
    my $name = $self->{'name'};
    return $wiz->param($name, '') unless defined($options);
    return $wiz->param($name, $options) unless ref($options) eq 'ARRAY';
    return $wiz->param($name, '') unless @$options;

    $form->print("$self->{'descr'}:\n");
    my $i = 0;
    my $num = 1;
    foreach my $opt (@$options) {
	$form->print((($opt eq $value) ? ' ($)'  : '    ') . ++$i 
		     . ": $opt\n");
	$num = $i if ($opt eq $value);
    }
    while (1) {
	$form->print("\nEnter a number: [$num] ");
	my $reply = $form->readline();
	chomp $reply;
	$reply = $num if $reply eq '';
	next unless $reply =~ /^\d+$/;
	next if $reply == 0  ||  $reply > @$options;
	return $wiz->param($name, $options->[$reply-1]);
    }
}


1;



