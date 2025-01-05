package Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota;

use base qw(Wikibase::Datatype::Item);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SubjectLexeme::Dorota;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::FemaleGivenName;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.37;

sub new {
	my $class = shift;

	my @params = (
		'aliases' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Dorota (given name)',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Dorota (first name)',
			),
		],
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'female given name',
			),
		],
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Dorota',
			),
		],
		'lastrevid' => 1963851086,
		'modified' => '2023-08-29T14:07:10Z',
		'ns' => 0,
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::FemaleGivenName->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SubjectLexeme::Dorota->new,
		],
		'title' => 'Q1246129',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota - Test instance for Wikidata item.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota->new;
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

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota->new;

Constructor.

Returns instance of object.

=head2 C<aliases>

 my $aliases_ar = $obj->aliases;

Get aliases.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

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

=for comment filename=fixture_create_and_print_item_wd_dorota.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota;
 use Wikibase::Datatype::Print::Item;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Item::print($obj);

 # Output:
 # Label: Dorota (en)
 # Description: female given name (en)
 # Aliases:
 #   Dorota (given name) (en)
 #   Dorota (first name) (en)
 # Statements:
 #   P31: Q11879590 (normal)
 #   References:
 #     {
 #       P248: Q53919
 #       P214: 113230702
 #       P813: 7 December 2013 (Q1985727)
 #     }
 #   P6254: L42284 (normal)
 #   References:
 #     {
 #       P854: https://skim.cz
 #       P813: 7 December 2013 (Q1985727)
 #     }
 #     {
 #       P248: Q53919
 #       P214: 113230702
 #       P813: 7 December 2013 (Q1985727)
 #     }

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SubjectLexeme::Dorota>,
L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::FemaleGivenName>,
L<Wikibase::Datatype::Item>,
L<Wikibase::Datatype::Value::Monolingual>.

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

0.37

=cut
