package XML::Parser::ClinicalTrials::Study::Location;
$XML::Parser::ClinicalTrials::Study::Location::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;
use constant PREFIX => 'XML::Parser::ClinicalTrials::Study';

has_xpath_value       term          => './mesh_term';
has_xpath_object_list investigators => './investigator'
                                    => PREFIX . '::Location';
has_xpath_object_list contacts      => './contact'
                                    => PREFIX . '::Contact';
has_xpath_object_list facilities    => './facility'
                                    => PREFIX . '::Facility';

finalize_class();

__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::Location - XML representation of ClinicalTrials study location data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

Location instances have one value accessor, C<term>.

=head2 Object Accessors

These accessors provide array references of other Moose objects with their own
accessors. Where a value is not present in the source XML file, the returned
array reference will be empty.

=over 4

=item * investigators

An array reference of L<XML::Parser::ClinicalTrials::Study::Location> objects.

=item * contacts

An array reference of L<XML::Parser::ClinicalTrials::Study::Contact> objects.

=item * facilities

An array reference of L<XML::Parser::ClinicalTrials::Study::Facility> objects.

=back

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
