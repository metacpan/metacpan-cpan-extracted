=head1 NAME

PPIx::Regexp::Structure::Capture - Represent capture parentheses.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Capture> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Capture> is the parent of
L<PPIx::Regexp::Structure::NamedCapture|PPIx::Regexp::Structure::NamedCapture>.

=head1 DESCRIPTION

This class represents capture parentheses.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Structure::Capture;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub explain {
    my ( $self ) = @_;
    return sprintf q<Capture group number %s>, $self->number();
}

=head2 name

 my $name = $element->name();

This method returns the name of the capture buffer. Unless the buffer is
actually named, this will be C<undef>.

=cut

sub name {
    return;
}

=head2 number

 my $number = $element->number()

This method returns the number of the capture buffer. Note that named
buffers have numbers also.

=cut

sub number {
    my ( $self ) = @_;
    return $self->{number};
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    $self->{number} = $number++;
    return $self->SUPER::__PPIX_LEXER__record_capture_number( $number );
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
