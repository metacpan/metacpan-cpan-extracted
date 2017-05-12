package XML::Parser::ClinicalTrials::Study::Design;
$XML::Parser::ClinicalTrials::Study::Design::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;

has_xpath_value design => '.';

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::Design - XML representation of ClinicalTrials study design data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

Design instances have only one simple value accessor, C<design>.

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
