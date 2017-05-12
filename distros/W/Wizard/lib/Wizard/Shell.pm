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

use Wizard ();
use Wizard::Form::Shell ();


=pod

=head1 NAME

Wizard::Shell - A subclass for running Wizard applications in a shell.


=head1 SYNOPSIS

  # Create a new shell wizard
  use Wizard::Shell;
  my $wiz = Wizard::Shell->new('form' => $form)


=head1 DESCRIPTION

The Shell wizard is a subclass of Wizard, that will run in a shell. The
input elements are written to stdout and the application will query you
for input.

=cut

package Wizard::Shell;

@Wizard::Shell::ISA = qw(Wizard);


sub new {
    my $self = shift;  my $attr = shift;
    $attr->{'formClass'} ||= 'Wizard::Form::Shell';
    $self->SUPER::new($attr);
}


sub State {
    my $self = shift;
    if (@_) {
	$self->{'state'} = shift;
    }
    $self->{'state'};
}

sub param {
    my $self = shift;
    my $params = $self->{'params'} || {};
    return keys %$params unless (@_);
    my $var = shift;
    my $vars = $params->{$var} || [];
    if (@_) {
	my $val = shift;
	$vars = (defined($val) and ref($val)) ? $val : [$val];
	$self->{'params'}->{$var} = $vars;
    }
    wantarray ? @$vars : $vars->[0];
}

# Store is a dummy method here, because we need no persistency
sub Store {  }

sub ResetParam { shift->{'params'} = {} }


1;

__END__

=pod

=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@ispsoft.de
                         Phone: +49 7123 14887

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@ispsoft.de
                         Phone: +49 7072 920696

All Rights Reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=cut




