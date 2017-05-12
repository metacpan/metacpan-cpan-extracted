package Weather::Bug::Temperature;

use warnings;
use strict;
use Moose;
use XML::LibXML;

use overload
    '""' => \&stringify;

our $VERSION = '0.25';

extends 'Weather::Bug::Quantity';

has 'f' => ( is => 'ro', isa => 'Num', default => 0.0 );
has 'c' => ( is => 'ro', isa => 'Num', default => 0.0 );
has 'is_SI' => ( is => 'rw', isa => 'Bool', init_arg => '-si' );

sub from_xml
{
    my $class = shift;
    my $node = shift;

    die "No node found.\n" unless defined $node;

    return Weather::Bug::Temperature->new(
        -value => $node->findvalue( '.' ),
        -units => ($node->findvalue( '@unit' ) || $node->findvalue( '@units' )),
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

    my $value = $params->{'-value'};
    $value =~ tr/-0-9.//cd;

    if( '--' eq $value )
    {
        $self->{is_SI} = undef;
        return;
    }

    my $dec = 0;
    $dec = length $1 if $value =~ /\.(\d+)/;

    if( $unit eq 'C' )
    {
        $self->{is_SI} = 1;
        $self->{f} = _precision( $value*1.8 + 32, $dec );
        $self->{c} = $value;
    }
    elsif( $unit eq 'F' )
    {
        $self->{is_SI} = 0;
        $self->{c} = _precision( ($value-32)/1.8, $dec );
        $self->{f} = $value;
    }
    else
    {
        die "Unknown units for temperature.\n";
    }

    return;
}

sub stringify
{
    my $self = shift;

    return 'N/A' if $self->is_null(); 
    return $self->is_SI() ? ($self->c() . " C") : ($self->f() . " F");
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Temperature - Abstraction for temperature with the
ability to retrieve data in either C or F.

=head1 VERSION

This document describes Weather::Bug::Temperature version 0.25

=head1 SYNOPSIS

    use Weather::Bug::Temperature;

    my $t = Weather::Bug::Temperature->new( -value => 78, -units => 'F' );

    print "Temperature in Celsius: ", $t->c(), "\n";

=head1 DESCRIPTION

Much of the information returned from the WeatherBug API is temperature data.
Since normal, outside temperatures can be usefully be returned as values on
either the Celsius or Fahrenheit scales, this class serves to abstract that
distinction for the user.

=head1 INTERFACE 

This class supports one factory method and a set of accessor methods.

=head2 Factory Method

=over 4

=item from_xml

This method expects an L<XML::LibXML> Node object that describes a temperature.
Based on the examples in the WeatherBug API, we expect the temperature value
to be the value of the node and the units to be specified in the I<unit>
attribute.

=back

=head2 Accessor Methods

=over 4

=item f

Return the value of the temperature on the Fahrenheit scale. The value returned
will have the same digits of precision as the original value.

=item c

Return the value of the temperature on the Celsius scale. The value returned
will have the same digits of precision as the original value.

=item is_SI

Returns a true value if the original temperature was in Celsius, false
otherwise.

=item stringify

Format the temperature and units as a string. If the temperature is null,
the string value will be I<N/A>.

=back

=head1 DIAGNOSTICS

=over

=item C<< No node found. >>

No node was passed to from_xml 

=item C<< Unknown units for temperature. >>

The supplied units were neither 'C' nor 'F'.

=back

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
