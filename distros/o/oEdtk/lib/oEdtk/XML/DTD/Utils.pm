package oEdtk::XML::DTD::Utils;
use strict;
use warnings;

use oEdtk::XML::DTD;
our $VERSION = '2.1129';

# oEdtk::XML::DTD::Utils was the fork's name for the DTD validator; it was merged
# into oEdtk::XML::DTD at S21 (the two were about 90% identical). This module stays
# loadable for the fork's parked callers and forwards every function, so the
# symbols resolve under their old name.
sub found_in_list                   { return oEdtk::XML::DTD::found_in_list(@_) }
sub load_xml_catalogs               { return oEdtk::XML::DTD::load_xml_catalogs(@_) }
sub list_children_nodes             { return oEdtk::XML::DTD::list_children_nodes(@_) }
sub validate_xml                    { return oEdtk::XML::DTD::validate_xml(@_) }
sub parse_xml                       { return oEdtk::XML::DTD::parse_xml(@_) }
sub parse_and_validate_xml_file     { return oEdtk::XML::DTD::parse_and_validate_xml_file(@_) }
sub parse_and_validate_xml_string   { return oEdtk::XML::DTD::parse_and_validate_xml_string(@_) }
sub parse_and_validate_xml_file_xsd { return oEdtk::XML::DTD::parse_and_validate_xml_file_xsd(@_) }
sub xml_to_txt                      { return oEdtk::XML::DTD::xml_to_txt(@_) }
sub first_id                        { return oEdtk::XML::DTD::first_id(@_) }
sub xpath                           { return oEdtk::XML::DTD::xpath(@_) }

1;

=head1 NAME

oEdtk::XML::DTD::Utils - delegate to oEdtk::XML::DTD

=head1 SYNOPSIS

    use oEdtk::XML::DTD::Utils;

    oEdtk::XML::DTD::Utils::parse_and_validate_xml_file($file, \@ids);

=head1 DESCRIPTION

The fork shipped this module alongside F<oEdtk::XML::DTD>; the two were about 90%
identical and were merged into L<oEdtk::XML::DTD> at S21 of the fork-merge plan.
This module keeps the old name available to the fork's callers and forwards every
function to L<oEdtk::XML::DTD>.

=head1 FUNCTIONS

Every function below forwards its arguments to the same-named function in
L<oEdtk::XML::DTD> and returns its result:

=over 4

=item found_in_list

=item load_xml_catalogs

=item list_children_nodes

=item validate_xml

=item parse_xml

=item parse_and_validate_xml_file

=item parse_and_validate_xml_string

=item parse_and_validate_xml_file_xsd

=item xml_to_txt

=item first_id

=item xpath

=back

=head1 AUTHOR

The oEdtk team.

=cut
