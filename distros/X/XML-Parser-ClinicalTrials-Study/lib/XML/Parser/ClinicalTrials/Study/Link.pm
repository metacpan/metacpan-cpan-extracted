package XML::Parser::ClinicalTrials::Study::Link;
$XML::Parser::ClinicalTrials::Study::Link::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;

has_xpath_value url         => './url';
has_xpath_value description => './description';

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::Link - XML representation of ClinicalTrials study link data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

Link instances have two simple value accessors.

=head2 Value Accessors

These accessors provide simple values. When a value is not present in the XML
file, this accessor will return the empty string.

=over 4

=item * url

=item * description

=back

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
