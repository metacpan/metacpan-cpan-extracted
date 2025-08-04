package Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;

use base qw(Wikibase::Datatype::Lexeme);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.39;

sub new {
	my $class = shift;

	my @params = (
		'forms' => [
			Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new,
		],
		'id' => 'L469',
		'language' => 'Q9056',
		'lastrevid' => 1428556087,
		'lexical_category' => 'Q1084',
		'lemmas' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => 'pes',
			),
		],
		'modified' => '2022-06-24T12:42:10Z',
		'ns' => 146,
		'page_id' => 54393954,
		'senses' => [
			Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new,
		],
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine->new,
		],
		'title' => 'Lexeme:L469',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun - Test instance for Wikidata form.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
 my $forms_ar = $obj->forms;
 my $id = $obj->id;
 my $language = $obj->language;
 my $lastrevid = $obj->lastrevid;
 my $lemmas_ar = $obj->lemmas;
 my $lexical_category = $obj->lexical_category;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $senses_ar = $obj->senses;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new(%params);

Constructor.

Returns instance of object.

=head2 C<forms>

 my $forms_ar = $obj->forms;

Get forms.

Returns reference to array with Wikibase::Datatype::Form instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<language>

 my $language = $obj->language;

Get language.

Returns string with QID.

=head2 C<lastrevid>

 my $lastrevid = $obj->lastrevid;

Get last revision ID.

Returns string.

=head2 C<lemmas>

 my $lemmas_ar = $obj->lemmas;

Get lemmas.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<lexical_category>

 my $lexical_category = $obj->lexical_category;

Get lexical category.

Returns string with QID.

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

=head2 C<senses>

 my $senses_ar = $obj->senses;

Get senses.

Returns reference to array with Wikibase::Datatype::Sense instances.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array with Wikibase::Datatype::Statement instances.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_lexeme_wd_dog_czech_noun.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
 use Unicode::UTF8 qw(encode_utf8);
 use Wikibase::Datatype::Print::Lexeme;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;

 # Print out.
 print encode_utf8(scalar Wikibase::Datatype::Print::Lexeme::print($obj));

 # Output:
 # Title: Lexeme:L469
 # Lemmas: pes (cs)
 # Language: Q9056
 # Lexical category: Q1084
 # Statements:
 #   P5185: Q499327 (normal)
 #   References:
 #     {
 #       P248: Q53919
 #       P214: 113230702
 #       P813: 7 December 2013 (Q1985727)
 #     }
 # Senses:
 #   Id: L469-S1
 #   Glosses:
 #     domesticated mammal related to the wolf (en)
 #     psovitá šelma chovaná jako domácí zvíře (cs)
 #   Statements:
 #     P18: Canadian Inuit Dog.jpg (normal)
 #     P5137: Q144 (normal)
 # Forms:
 #   Id: L469-F1
 #   Representation: pes (cs)
 #   Grammatical features: Q110786, Q131105
 #   Statements:
 #     P898: pɛs (normal)

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular>,
L<Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog>,
L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine>,
L<Wikibase::Datatype::Lexeme>,
L<Wikibase::Datatype::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Lexeme>

Wikibase lexeme datatype.

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
