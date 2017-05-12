package XML::Parser::ClinicalTrials::Study::MeSHTerm;
$XML::Parser::ClinicalTrials::Study::MeSHTerm::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;

has_xpath_value term => '.';

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::MeSHTerm - XML representation of ClinicalTrials study MeSH term data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

MeSHTerm instances have a single simple value accessor, C<term>.

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
