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
use Wizard::Form::HTML ();


=pod

=head1 NAME

Wizard::HTML - A subclass for running Wizard applications in HTML::EP.


=head1 SYNOPSIS

  # Create a new HTML wizard
  use Wizard::HTML;
  my $wiz = Wizard::Shell->new('form' => $form, 'ep' => $ep)


=head1 DESCRIPTION

The HTML wizard is a subclass of Wizard, that is used by HTML::EP sites.
The input will be read from the associated CGI-Object and the output 
as HTML code will be built by the elements of the form.

=cut

package Wizard::HTML;

@Wizard::HTML::ISA = qw(Wizard);

sub new {
    my $self = shift;  my $attr = shift;
    $attr->{'formClass'} ||= 'Wizard::Form::HTML';
    die "No valid ep object" unless ref($attr->{'ep'});
    $self = $self->SUPER::new($attr);
    $self->{'ep'}->{'_ep_wizard'} = $self;
}


sub param { return shift->{'ep'}->{'cgi'}->param(@_); };


sub Store {  
    my $self = shift; my $state = shift;
    my $ep = $self->{'ep'} || die "no valid ep object available";
    $ep->{'state_modified'} = 1;
    $ep->{'session'}->{'state'} = $state;
}

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

