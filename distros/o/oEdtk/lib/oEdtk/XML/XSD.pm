package oEdtk::XML::XSD;
use strict;
use warnings;

use Carp;
use XML::LibXML;
our $VERSION = '2.1131';

# Validate a file against an XSD schema. XML::LibXML::Schema::validate returns a
# false value when the document is valid and dies with the validation errors when
# it is not, so the check keys on the exception. That is stable across XML::LibXML
# releases; the fork's "not validate(...)" keyed on the return value instead and
# was only accidentally correct.
sub parse_and_validate_xml_file_xsd {
	my ( $file, $cfg ) = @_;
	my $xml_doc = XML::LibXML->load_xml( location => $file );
	my $xsd_doc = XML::LibXML::Schema->new( location => $cfg );
	my $ok      = eval { $xsd_doc->validate($xml_doc); 1 };
	croak "XML ($file) does not validate with XSD ($cfg): " . ( $@ // q{} )
		unless $ok;
	return 1;
}

1;

=head1 NAME

oEdtk::XML::XSD - validate an XML file against an XSD schema

=head1 SYNOPSIS

    use oEdtk::XML::XSD;

    oEdtk::XML::XSD::parse_and_validate_xml_file_xsd($xml_file, $xsd_file);

=head1 DESCRIPTION

Thin wrapper over L<XML::LibXML::Schema>. It dies when the document does not
validate. Moved into the mainline from the 0.8032 fork at S21 of the fork-merge
plan.

=head1 FUNCTIONS

=head2 parse_and_validate_xml_file_xsd

    parse_and_validate_xml_file_xsd($xml_file, $xsd_schema);

Load C<$xml_file>, validate it against the XSD schema C<$xsd_schema> and return
true. The function croaks with the validation errors, prefixed by the two file
names, when the document is invalid. Note that C<XML::LibXML::Schema::validate>
returns a false value on success and dies on failure, which is what the check
relies on; see F<t/int/35_xml_dtd_xsd.t>.

=head1 AUTHOR

The oEdtk team.

=cut
