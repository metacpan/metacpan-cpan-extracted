package Weather::Bug::Quantity;

use warnings;
use strict;
use Moose;
use XML::LibXML;

use overload
    '""' => \&stringify;

our $VERSION = '0.25';

has 'value' => ( is => 'ro', isa => 'Str', init_arg => '-value' );
has 'units' => ( is => 'ro', isa => 'Str', init_arg => '-units' );

sub from_xml
{
    my $class = shift;
    my $node = shift;

    return Weather::Bug::Quantity->new(
        -value => $node->findvalue( '.' ),
        -units => $node->findvalue( '@units' ),
    );
}

sub _precision
{
    my $value = shift;
    my $dec = shift;

    return int($value) if 0 == $dec;
    return sprintf( "%.${dec}f", $value );
}

sub BUILD
{
    my $self = shift;
    my $params = shift;

    my $unit = $params->{'-units'};
    $unit =~ s/&deg;//;
    $unit =~ s/"/in/;
    $self->{units} = $unit;

    my $value = $params->{'-value'};

    if( '--' eq $value || 'N/A' eq uc $value )
    {
        $self->{value} = undef;
        return;
    }
    $value =~ tr/-0-9.//cd;

    $self->{value} = $value;

    return;
}

sub is_null
{
    my $self = shift;

    return !defined( $self->value() );
}

sub stringify
{
    my $self = shift;

    return 'N/A' if $self->is_null(); 
    return $self->value() . " " . $self->units();
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Quantity - Abstraction for a value with units.

=head1 VERSION

This document describes Weather::Bug::Quantity version 0.25

=head1 SYNOPSIS

    use Weather::Bug::Quantity;

    my $q = Weather::Bug::Quantity( -value => 5.1, -units => 'm' );

    print "Distance: $q\n" unless $q->is_null();

=head1 DESCRIPTION

This class represents numeric values that have associated units. It can also
represent a null object for cases where no value was available.

=head1 INTERFACE 

This class supports one factory method and a set of accessor methods.

=head2 Factory Method

=over 4

=item from_xml

This class method expects a single L<XML::LibXML> node method with the value
being the value of the node and the units specified in I<units> attribute.

=back

=head2 Accessor Methods

=over 4

=item value

The numeric value represented by the object.

=item units

The units of the Quantity returned as a string.

=item is_null

Returns a false value if the Quantity has a value, a true value otherwise.

=item stringify

Convert the quantity into a printable string (value followed by units) unless
the value is null. If the Quantity is null, return I<N/A>.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Weather::Bug requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Moose>, C<XML::LibXML>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-weather-weatherbug@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< <wade@anomaly.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, G. Wade Johnson C<< <wade@anomaly.org> >>. All rights reserved.

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
