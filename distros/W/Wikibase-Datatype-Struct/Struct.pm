package Wikibase::Datatype::Struct;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Struct::Item;
use Wikibase::Datatype::Struct::Lexeme;
use Wikibase::Datatype::Struct::Mediainfo;
use Wikibase::Datatype::Struct::Property;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.14;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr;
	if ($obj->isa('Wikibase::Datatype::Item')) {
		$struct_hr = Wikibase::Datatype::Struct::Item::obj2struct($obj, $base_uri);
	} elsif ($obj->isa('Wikibase::Datatype::Lexeme')) {
		$struct_hr = Wikibase::Datatype::Struct::Lexeme::obj2struct($obj, $base_uri);
	} elsif ($obj->isa('Wikibase::Datatype::Mediainfo')) {
		$struct_hr = Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj, $base_uri);
	} elsif ($obj->isa('Wikibase::Datatype::Property')) {
		$struct_hr = Wikibase::Datatype::Struct::Property::obj2struct($obj, $base_uri);
	} else {
		my $ref = ref $obj;
		err "Unsupported Wikibase::Datatype object.",
			defined $ref ? ('Reference', $ref) : (),
		;
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}) {
		err "Structure doesn't supported. No type.";
	}

	my $obj;
	if ($struct_hr->{'type'} eq 'item') {
		$obj = Wikibase::Datatype::Struct::Item::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'lexeme') {
		$obj = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'mediainfo') {
		$obj = Wikibase::Datatype::Struct::Mediainfo::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'property') {
		$obj = Wikibase::Datatype::Struct::Property::struct2obj($struct_hr);
	} else {
		err "Unsupported '$struct_hr->{'type'}' type,";
	}

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct - Wikibase structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert main instances to structure.
Supported instances are L<Wikibase::Datatype::Item>, L<Wikibase::Datatype::Lexeme>,
L<Wikibase::Datatype::Mediainfo> and L<Wikibase::Datatype::Property>.
C<$base_uri> is base URI of Wikibase system (e.g. L<http://test.wikidata.org/entity/>).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of item to object.
Supported types are: 'item', 'lexeme', 'mediainfo' and 'property'.

Returns L<Wikibase::Datatype::Item>, L<Wikibase::Datatype::Lexeme>,
L<Wikibase::Datatype::Mediainfo> or L<Wikibase::Datatype::Property> instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Unsupported Wikibase::Datatype object.
                 Reference: %s

 struct2obj():
         Structure doesn't supported. No type.
         Unsupported '%s' type,

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Struct::Item>,
L<Wikibase::Datatype::Struct::Lexeme>,
L<Wikibase::Datatype::Struct::Mediainfo>,
L<Wikibase::Datatype::Struct::Property>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct::Form>

Wikibase form structure serialization.

=item L<Wikibase::Datatype::Struct::Item>

Wikibase item structure serialization.

=item L<Wikibase::Datatype::Struct::Lexeme>

Wikibase lexeme structure serialization.

=item L<Wikibase::Datatype::Struct::Mediainfo>

Wikibase mediainfo structure serialization.

=item L<Wikibase::Datatype::Struct::MediainfoSnak>

Wikibase mediainfo snak structure serialization.

=item L<Wikibase::Datatype::Struct::MediainfoStatement>

Wikibase mediainfo statement structure serialization.

=item L<Wikibase::Datatype::Struct::Property>

Wikibase property structure serialization.

=item L<Wikibase::Datatype::Struct::Reference>

Wikibase reference structure serialization.

=item L<Wikibase::Datatype::Struct::Sense>

Wikibase sense structure serialization.

=item L<Wikibase::Datatype::Struct::Sitelink>

Wikibase sitelink structure serialization.

=item L<Wikibase::Datatype::Struct::Snak>

Wikibase snak structure serialization.

=item L<Wikibase::Datatype::Struct::Statement>

Wikibase statement structure serialization.

=item L<Wikibase::Datatype::Struct::Utils>

Wikibase structure serialization utilities.

=item L<Wikibase::Datatype::Struct::Value>

Wikibase value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Globecoordinate>

Wikibase globe coordinate value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Item>

Wikibase item value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Lexeme>

Wikibase lexeme value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Monolingual>

Wikibase monolingual value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Property>

Wikibase property value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Quantity>

Wikibase quantity value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Sense>

Wikibase sense value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::String>

Wikibase string value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Time>

Wikibase time value structure serialization.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.14

=cut
