package XML::Parser::ClinicalTrials::Study::Facility;
$XML::Parser::ClinicalTrials::Study::Facility::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;

has_xpath_value name    => './name';
has_xpath_value city    => './address/city';
has_xpath_value state   => './address/state';
has_xpath_value zip     => './address/zip';
has_xpath_value country => './address/country';

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::Facility - XML representation of ClinicalTrials study facility data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

Facility instances have several simple value accessors.

=head2 Value Accessors

These accessors provide simple values. When a value is not present in the XML
file, this accessor will return the empty string.

=over 4

=item * name

=item * city

=item * state

=item * zip

=item * country

=back

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
