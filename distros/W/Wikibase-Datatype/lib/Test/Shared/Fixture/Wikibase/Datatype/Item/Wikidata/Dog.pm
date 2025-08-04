package Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;

use base qw(Wikibase::Datatype::Item);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::Four;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Term;
use Wikibase::Datatype::Value::Item;

our $VERSION = 0.39;

sub new {
	my $class = shift;

	my @params = (
		'aliases' => [
			Wikibase::Datatype::Term->new(
				'language' => 'cs',
				'value' => decode_utf8('pes domácí'),
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'domestic dog',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'Canis lupus familiaris',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'Canis familiaris',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'dogs',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => decode_utf8('🐶'),
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => decode_utf8('🐕'),
			),
		],
		'descriptions' => [
			Wikibase::Datatype::Term->new(
				'language' => 'cs',
				'value' => decode_utf8('domácí zvíře'),
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'domestic animal',
			),
		],
		'labels' => [
			Wikibase::Datatype::Term->new(
				'language' => 'cs',
				'value' => 'pes',
			),
			Wikibase::Datatype::Term->new(
				'language' => 'en',
				'value' => 'dog',
			),
		],
		'id' => 'Q144',
		'lastrevid' => 1539465460,
		'modified' => '2021-12-06T14:48:31Z',
		'ns' => 0,
		'page_id' => 280,
		'sitelinks' => [
			Wikibase::Datatype::Sitelink->new(
				'site' => 'enwiki',
				'title' => 'Dog',
			),
		],
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::Four->new,
		],
		'title' => 'Q144',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog - Test instance for Wikidata item.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
 my $aliases_ar = $obj->aliases;
 my $descriptions_ar = $obj->descriptions;
 my $id = $obj->id;
 my $labels_ar = $obj->labels;
 my $lastrevid = $obj->lastrevid;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $sitelinks_ar = $obj->sitelinks;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

Constructor.

Returns instance of object.

=head2 C<aliases>

 my $aliases_ar = $obj->aliases;

Get aliases.

Returns reference to array with Wikibase::Datatype::Term instances.

=head2 C<descriptions>

 my $descriptions_ar = $obj->descriptions;

Get descriptions.

Returns reference to array with Wikibase::Datatype::Term instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<labels>

 my $labels_ar = $obj->labels;

Get labels.

Returns reference to array with Wikibase::Datatype::Term instances.

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

=head2 C<sitelinks>

 my $sitelinks_ar = $obj->sitelinks;

Get sitelinks.

Returns reference to array with Wikibase::Datatype::Sitelink instances.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array with Wikibase::Datatype::Statement instances.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_item_wd_dog.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
 use Unicode::UTF8 qw(encode_utf8);
 use Wikibase::Datatype::Print::Item;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

 # Print out.
 print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($obj));

 # Output:
 # Label: dog (en)
 # Description: domestic animal (en)
 # Aliases:
 #   domestic dog (en)
 #   Canis lupus familiaris (en)
 #   Canis familiaris (en)
 #   dogs (en)
 #   🐶 (en)
 #   🐕 (en)
 # Sitelinks:
 #   Dog (enwiki)
 # Statements:
 #   P31: Q55983715 (normal)
 #    P642: Q20717272
 #    P642: Q26972265
 #   P123456789: 4 (normal)

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism>,
L<Unicode::UTF8>,
L<Wikibase::Datatype::Sitelink>,
L<Wikibase::Datatype::Statement>,
L<Wikibase::Datatype::Snak>,
L<Wikibase::Datatype::Term>,
L<Wikibase::Datatype::Value::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Item>

Wikibase item datatype.

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

0.39

=cut
