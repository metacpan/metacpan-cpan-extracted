package Wikibase::Datatype::Struct::Mediainfo;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::Struct::Language;
use Wikibase::Datatype::Struct::MediainfoStatement;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.09;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Mediainfo')) {
		err "Object isn't 'Wikibase::Datatype::Mediainfo'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		'type' => 'mediainfo',
	};

	# Claims.
	foreach my $statement (@{$obj->statements}) {
		$struct_hr->{'statements'}->{$statement->snak->property} //= [];
		push @{$struct_hr->{'statements'}->{$statement->snak->property}},
			Wikibase::Datatype::Struct::MediainfoStatement::obj2struct($statement, $base_uri);
	}

	# Descriptions.
	$struct_hr->{'descriptions'} = {};
	foreach my $desc (@{$obj->descriptions}) {
		$struct_hr->{'descriptions'}->{$desc->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($desc);
	}

	# Id.
	if (defined $obj->id) {
		$struct_hr->{'id'} = $obj->id;
	}

	# Labels.
	foreach my $label (@{$obj->labels}) {
		$struct_hr->{'labels'}->{$label->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($label);
	}
	
	# Last revision id.
	if (defined $obj->lastrevid) {
		$struct_hr->{'lastrevid'} = $obj->lastrevid;
	}

	# Modified date.
	if (defined $obj->modified) {
		$struct_hr->{'modified'} = $obj->modified;
	}

	# Namespace.
	if (defined $obj->ns) {
		$struct_hr->{'ns'} = $obj->ns;
	}

	# Page ID.
	if (defined $obj->page_id) {
		$struct_hr->{'pageid'} = $obj->page_id;
	}

	# Title.
	if (defined $obj->title) {
		$struct_hr->{'title'} = $obj->title;
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'} || $struct_hr->{'type'} ne 'mediainfo') {
		err "Structure isn't for 'mediainfo' type.";
	}

	# Descriptions.
	my $descriptions_ar = [];
	foreach my $lang (keys %{$struct_hr->{'descriptions'}}) {
		push @{$descriptions_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
			$struct_hr->{'descriptions'}->{$lang},
		);
	}

	# Labels.
	my $labels_ar = [];
	foreach my $lang (keys %{$struct_hr->{'labels'}}) {
		push @{$labels_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
			$struct_hr->{'labels'}->{$lang},
		);
	}

	# Statements.
	my $statements_ar = [];
	foreach my $property (keys %{$struct_hr->{'statements'}}) {
		foreach my $claim_hr (@{$struct_hr->{'statements'}->{$property}}) {
			push @{$statements_ar}, Wikibase::Datatype::Struct::MediainfoStatement::struct2obj(
				$claim_hr,
			);
		}
	}

	my $obj = Wikibase::Datatype::Mediainfo->new(
		'descriptions' => $descriptions_ar,
		defined $struct_hr->{'id'} ? ('id' => $struct_hr->{'id'}) : (),
		'labels' => $labels_ar,
		defined $struct_hr->{'lastrevid'} ? ('lastrevid' => $struct_hr->{'lastrevid'}) : (),
		defined $struct_hr->{'modified'} ? ('modified' => $struct_hr->{'modified'}) : (),
		defined $struct_hr->{'ns'} ? ('ns' => $struct_hr->{'ns'}) : (),
		defined $struct_hr->{'pageid'} ? ('page_id' => $struct_hr->{'pageid'}) : (),
		'statements' => $statements_ar,
		defined $struct_hr->{'title'} ? ('title' => $struct_hr->{'title'}) : (),
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Mediainfo - Wikibase mediainfo structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Mediainfo qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Mediainfo instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of mediainfo to object.

Returns Wikibase::Datatype::Mediainfo instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Mediainfo'.

 struct2obj():
         Structure isn't for 'mediainfo' type.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Mediainfo;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::MediainfoStatement;
 use Wikibase::Datatype::Struct::Mediainfo qw(obj2struct);
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;

 # Object.
 my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                 'value' => 'Q474741',
                         ),
                         'property' => 'P642',
                 ),
         ],
 );
 my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
         # sex or gender (P21) male (Q6581097)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q6581097',
                 ),
                 'property' => 'P21',
         ),
 );

 # Main item.
 my $obj = Wikibase::Datatype::Mediainfo->new(
         'id' => 'Q42',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas Adams',
                 ),
         ],
         'page_id' => 123,
         'statements' => [
                 $statement1,
                 $statement2,
         ],
         'title' => 'Q42',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # TODO

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Struct::Mediainfo qw(struct2obj);

 # Item structure.
 my $struct_hr = {
 # TODO
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Print out.
 p $obj;

 # Output:
 # TODO

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Mediainfo>,
L<Wikibase::Datatype::Struct::Language>,
L<Wikibase::Datatype::Struct::MediainfoStatement>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Mediainfo>

Wikibase mediainfo datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
