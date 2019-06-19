package WebService::MinFraud::Record::IPAddress;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use B;
use GeoIP2::Role::Model::Location 2.004000;
use GeoIP2::Role::Model::HasSubdivisions;
use Types::Standard qw( ArrayRef InstanceOf );
use Sub::Quote qw( quote_sub );
use WebService::MinFraud::Record::Location;
use WebService::MinFraud::Record::Country;

with 'GeoIP2::Role::Model::Location', 'GeoIP2::Role::Model::HasSubdivisions',
    'WebService::MinFraud::Role::Record::HasRisk';

## no critic (ProhibitUnusedPrivateSubroutines)
sub _has { has(@_) }
## use critic

__PACKAGE__->_define_attributes_for_keys( __PACKAGE__->_all_record_names() );

for my $name ( 'Country', 'Location' ) {
    my $attr = lc $name;

    my $raw_attr = '_raw_' . $attr;
    my $class    = "WebService::MinFraud::Record::$name";

    has "+$attr" => (
        is       => 'ro',
        isa      => InstanceOf [$class],
        init_arg => undef,
        lazy     => 1,
        default  => quote_sub(
            ## no critic (ProhibitCallsToUnexportedSubs)
            sprintf(
                q{ $_[0]->_build_mf_record( %s, %s ) },
                map { B::perlstring($_) } $class, $raw_attr
            )
        ),
        predicate => 1,
    );
}

sub _build_mf_record {
    my $self   = shift;
    my $class  = shift;
    my $method = shift;

    my $raw = $self->$method;

    return $class->new( %{$raw}, locales => $self->locales() );
}

1;

# ABSTRACT: Contains data for the IPAddress record returned from a minFraud web service query

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::IPAddress - Contains data for the IPAddress record returned from a minFraud web service query

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request    = { device => { ip_address => '24.24.24.24' } };
  my $insights   = $client->insights($request);
  my $ip_address = $insights->ip_address;
  say $ip_address->city->name;

=head1 DESCRIPTION

This class contains the GeoIP2 location data returned from a minFraud service
query for the given C<ip_address>.

=head1 METHODS

This class provides the following methods:

=head2 city

Returns a L<GeoIP2::Record::City> object representing city data for the IP
address.

=head2 continent

Returns a L<GeoIP2::Record::Continent> object representing continent data for
the IP address.

=head2 country

Returns a L<WebService::MinFraud::Record::Country> object for the IP address.
This record represents the country where MaxMind believes the IP is located.

=head2 location

Returns a L<WebService::MinFraud::Record::Location> object for the IP address.

=head2 most_specific_subdivision

Returns a L<GeoIP2::Record::Subdivision> object which is the most specific
(smallest) subdivision.

If the response did not contain any subdivisions, this method returns a
L<GeoIP2::Record::Subdivision> object with no values.

=head2 postal

Returns a L<GeoIP2::Record::Postal> object representing postal code data for
the IP address.

=head2 registered_country

Returns a L<GeoIP2::Record::Country> object representing the registered country
data for the IP address. This record represents the country where the ISP has
registered a given IP block and may differ from the user's country.

=head2 represented_country

Returns a L<GeoIP2::Record::RepresentedCountry> object for the country
represented by the IP address. The represented country may differ from the
country returned by the C<< country >> method, for locations such as military
bases.

=head2 risk

Returns the risk associated with the IP address. The value ranges from 0.01 to
99. A higher value indicates a higher risk. The IP address risk is distinct
from the value returned by C<< risk_score >> methods of
L<WebService::MinFraud::Model::Insights> and
L<WebService::MinFraud::Model::Score> modules.

=head2 subdivisions

Returns an array of L<GeoIP2::Record::Subdivision> objects representing the
country divisions for the IP address. The number and type of subdivisions
varies by country, but a subdivision is typically a state, province, county, or
administrative region.

=head2 traits

Returns a L<GeoIP2::Record::Traits> object representing traits for the IP
address, such as autonomous system number (ASN).

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_country

=head2 has_location

=head2 has_risk

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
