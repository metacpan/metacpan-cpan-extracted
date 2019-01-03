=head1 NAME

PPIx::Regexp::Structure::NamedCapture - Represent a named capture

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?<foo>foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::NamedCapture> is a
L<PPIx::Regexp::Structure::Capture|PPIx::Regexp::Structure::Capture>.

C<PPIx::Regexp::Structure::NamedCapture> has no descendants.

=head1 DESCRIPTION

This class represents a named capture. Its content will be something
like one of the following:

 (?<NAME> ... )
 (?'NAME' ... )
 (?P<NAME> ... )

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Structure::NamedCapture;

use strict;
use warnings;

use Carp;

use base qw{ PPIx::Regexp::Structure::Capture };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub explain {
    my ( $self ) = @_;
    return sprintf q<Named capture group '%s' (number %d)>,
	$self->name(), $self->number();
}

=head2 name

 my $name = $element->name();

This method returns the name of the capture.

=cut

sub name {
    my ( $self ) = @_;
    my $type = $self->type()
	or croak 'Programming error - ', __PACKAGE__, ' without type object';
    return $type->name();
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
