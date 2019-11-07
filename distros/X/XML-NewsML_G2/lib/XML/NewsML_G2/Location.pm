package XML::NewsML_G2::Location;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

has 'relevance', isa => 'Int', is => 'ro';
has 'parent', isa => __PACKAGE__, is => 'rw';
has 'direct', isa => 'Bool', is => 'rw', default => '';
has 'iso_code',  isa => 'Str', is => 'rw';
has 'longitude', isa => 'Num', is => 'rw';
has 'latitude',  isa => 'Num', is => 'rw';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Location - a location (city, region, country, ...)

=head1 SYNOPSIS

    my $at = XML::NewsML_G2::Location->new
        (name => 'Austria', qcode => 'at', relevance => 90, iso_code => 'AT');

    my $vie = XML::NewsML_G2::Location->new
        (name => 'Vienna', qcode => 'vie', relevance => 100, parent => $at);

=head1 ATTRIBUTES

=over 4

=item relevance

Value (0..100) specifying how relevant the location is for the news item

=item parent

points to the broader location (e.g., the city's country)

=item direct

whether the location has been manually specified by the editor

=item iso_code

for countries, the code in the ISO 3166-1a2 vocabulary - see
L<http://www.iso.org/iso/home/standards/country_codes/country_names_and_code_elements.htm>
for a reference

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
