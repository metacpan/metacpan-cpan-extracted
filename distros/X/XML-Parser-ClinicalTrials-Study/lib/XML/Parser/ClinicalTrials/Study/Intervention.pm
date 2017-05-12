package XML::Parser::ClinicalTrials::Study::Intervention;
$XML::Parser::ClinicalTrials::Study::Intervention::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;

has_xpath_value type  => './intervention_type';
has_xpath_value name  => './intervention_name';
has_xpath_value label => './arm_group_label';

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::Intervention - XML representation of ClinicalTrials study intervention data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

Intervention instances have several simple value accessors.

=head2 Value Accessors

These accessors provide simple values. When a value is not present in the XML
file, this accessor will return the empty string.

=over 4

=item * type

=item * name

=item * label

=back

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
