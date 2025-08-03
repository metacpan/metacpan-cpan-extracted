package Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;

use base qw(Wikibase::Datatype::Property);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.38;

sub new {
	my $class = shift;

	my @params = (
		'aliases' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'is a',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'is an',
			),
		],
		'datatype' => 'wikibase-item',
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'that class of which this subject is a particular example and member',
			),
		],
		'id' => 'P31',
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'instance of',
			),
		],
		'lastrevid' => 1645333097,
		'modified' => '2022-06-24T13:05:10Z',
		'page_id' => 3918489,
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty->new,
		],
		'title' => 'Property:P31',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf - Test instance for Wikidata property.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
 my $aliases_ar = $obj->aliases;
 my $datatype = $obj->datatype;
 my $descriptions_ar = $obj->descriptions;
 my $id = $obj->id;
 my $labels_ar = $obj->labels;
 my $lastrevid = $obj->lastrevid;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;

Constructor.

Returns instance of object.

=head2 C<aliases>

 my $aliases_ar = $obj->aliases;

Get aliases.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<datatype>

 my $datatype = $obj->datatype;

Get data type.

Returns string.

=head2 C<descriptions>

 my $descriptions_ar = $obj->descriptions;

Get descriptions.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<labels>

 my $labels_ar = $obj->labels;

Get labels.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<lastrevid>

 my $lastrevid = $obj->lastrevid;

Get last revision ID.

Returns string.

=head2 C<modified>

 my $modified = $obj->modified;

Get date of modification.

Returns string.

=head2 C<ns>

 my $ns = $obj->ns;

Get namespace.

Returns number.

=head2 C<page_id>

 my $page_id = $obj->page_id;

Get page id.

Returns number.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array with Wikibase::Datatype::Statement instances.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_property_wd_instance_of.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;
 use Wikibase::Datatype::Print::Property;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Property::print($obj);

 # Output:
 # Data type: wikibase-item
 # Label: instance of (en)
 # Description: that class of which this subject is a particular example and member (en)
 # Aliases:
 #   is a (en)
 #   is an (en)
 # Statements:
 #   P31: Q32753077 (normal)

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::WikidataProperty>,
L<Wikibase::Datatype::Property>,
L<Wikibase::Datatype::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Property>

Wikibase property datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.38

=cut
