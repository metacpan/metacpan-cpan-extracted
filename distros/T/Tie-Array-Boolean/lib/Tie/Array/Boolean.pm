package Tie::Array::Boolean;

$VERSION = '0.0.1';
@ISA = ( 'Tie::Array' );

use strict;
use warnings;

use Tie::Array;

sub TIEARRAY {
    my $class = shift;

    my $self = {
        bits  => '',
        size  => 0,
    };

    return bless $self, $class;
}

sub STORE {
    my $self  =    shift;
    my $index =    shift;
    my $value = !! shift;

    $self->STORESIZE( 1+$index ) if 1+$index > $self->FETCHSIZE();

    vec( $self->{bits}, $index, 1 ) = $value;

    return;
}

sub FETCH {
    my $self  = shift;
    my $index = shift;

    return undef if 1+$index > $self->FETCHSIZE();
    return vec( $self->{bits}, $index, 1 );
}

sub FETCHSIZE {
    my $self = shift;

    return $self->{size};
}

sub STORESIZE {
    my $self = shift;
    my $size = shift;

    if ( $size < $self->{size} ) {
        substr( $self->{bits}, int( $size / 8 ) + 1 ) = '';
        vec( $self->{bits}, $_, 1 ) = 0 for $size .. $size + 8;
    }

    $self->{size} = $size;

    return;
}

sub DELETE {
    my $self  = shift;
    my $index = shift;

    if ( $index == $self->FETCHSIZE() - 1 ) {
        $self->STORESIZE( $index );
    }
    else {
        $self->STORE( $index, 0 );
    }

    return;
}

sub EXISTS {
    my $self  = shift;
    my $index = shift;

    return $index < $self->FETCHSIZE();
}

sub get_truth_count {
    my $self = shift;

    return unpack '%32b*', $self->{bits};
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Tie::Array::Boolean - A memory efficient array of boolean values.

=head1 VERSION

This document describes Tie::Array::Boolean version 0.0.1

=head1 SYNOPSIS

    use Tie::Array::Boolean;

    tie my @t, 'Tie::Array::Boolean';

    # how many 'true' values are in the array
    my $true_count = tied(@t)->get_truth_count();

=head1 DESCRIPTION

This module implements an array as a scalar with each element represented
as one bit.  Every element of the array can be only 0 or 1.

=head1 INTERFACE

After an array has been tied to the module, it has the same interface
as a normal array.
Every value set to 0, undef, the string '0', or the empty string will be 0.
Every value set to anything else will be 1.

=head1 METHODS

=over 8

=item get_truth_count

Call this method on the object returned by C<tie> or C<tied>.
It will return the number of elements in the array that are true.
This is more efficient than counting values through the array interface.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT
  
Tie::Array::Boolean requires no configuration files or environment variables.

=head1 DEPENDENCIES

Tie::Array::Boolean uses only the core module, Tie::Array.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

=over 8

=item *

The array doesn't always contract in size like a real one would when
items are deleted.

=item *

There are no undef values.  If you delete a value in the middle of the
array, it will be set to 0.

=back

Please report any bugs or feature requests to
C<bug-tie-array-boolean@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kyle Hasselbacher  C<< <kyleha@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kyle Hasselbacher C<< <kyleha@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
