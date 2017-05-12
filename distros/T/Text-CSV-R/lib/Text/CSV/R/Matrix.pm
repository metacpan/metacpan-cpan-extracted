package Text::CSV::R::Matrix;

require 5.005;

use strict;
use warnings;

use Carp;
use Tie::Array;
use Scalar::Util qw(reftype looks_like_number);

our @ISA = 'Tie::Array';

our $VERSION = '0.3';

sub TIEARRAY {
    my ($self) = @_;
    return bless { ARRAY => [], ROWNAMES => [], COLNAMES => [], }, $self;
}

sub FETCH {
    my ( $self, $index ) = @_;
    return $self->{ARRAY}->[$index];
}

sub STORE {
    my ( $self, $index, $value ) = @_;
    $self->{ARRAY}->[$index] = $value;
    return;
}

sub FETCHSIZE {
    my $self = shift;
    return scalar @{ $self->{ARRAY} };
}

sub STORESIZE {
    my ( $self, $value ) = @_;
    $#{ $self->{ARRAY} }    = $value - 1;
    $#{ $self->{ROWNAMES} } = $value - 1;
    return;
}

sub EXTEND {
    my ( $self, $count ) = @_;
    $self->STORESIZE($count);
    return;
}

sub SPLICE {
    my $ob  = shift;
    my $sz  = $ob->FETCHSIZE;
    my $off = @_ ? shift : 0;
    if ( $off < 0 ) {
        $off += $sz;
    }
    my $len = @_ ? shift : $sz - $off;

    # if LIST provided, empty new ROWNAMES
    my @rn = map {q{}} @_;
    splice @{ $ob->{ROWNAMES} }, $off, $len, @rn;
    return splice @{ $ob->{ARRAY} }, $off, $len, @_;
}

sub COLNAMES {
    my ( $self, $values ) = @_;
    if ( defined $values ) {
        if ( !_is_array_ref($values) ) {
            croak 'Invalid colnames length';
        }
        $self->{COLNAMES} = $values;
    }
    return $self->{COLNAMES};
}

sub ROWNAMES {
    my ( $self, $values ) = @_;
    if ( defined $values ) {
        if ( !_is_array_ref($values)
            || scalar @{$values} != scalar @{ $self->{ARRAY} } )
        {
            croak 'Invalid rownames length';
        }
        $self->{ROWNAMES} = $values;
    }
    return $self->{ROWNAMES};
}

sub _is_array_ref {
    my ($values) = @_;
    return ( defined reftype $values && reftype $values eq 'ARRAY' ) ? 1 : 0;
}

1;
__END__

=head1 NAME

Text::CSV::R::Matrix - Tied array with column and row names.

=head1 DESCRIPTION

This is the return object of the Text::CSV::R read_* functions. 
It's just a (two-dimensional) array with column and row names attached.

=head1 INTERFACE

The following subroutines are not exported. You should use the subroutines
exported by L<Text::CSV::R> instead.

=over

=item COLNAMES(@tied_array, $array_ref) 

Get and set (if C<$array_ref> defined) the colnames.

=item ROWNAMES(@tied_array, $array_ref) 

Get and set (if C<$array_ref> defined) the rownames.

=back

=head1 SEE ALSO

L<Text::CSV>, L<Text::CSV::R>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 E<lt>limaone@cpan.orgE<gt>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
