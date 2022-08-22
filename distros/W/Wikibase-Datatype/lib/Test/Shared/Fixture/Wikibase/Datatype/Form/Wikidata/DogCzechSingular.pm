package Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;

use base qw(Wikibase::Datatype::Form);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;

our $VERSION = 0.20;

sub new {
	my $class = shift;

	my @params = (
		'grammatical_features' => [
			# singular
			Wikibase::Datatype::Value::Item->new(
				'value' => 'Q110786',
			),
			# nominative case
			Wikibase::Datatype::Value::Item->new(
				'value' => 'Q131105',
			),
		],
		'id' => 'L469-F1',
		'representations' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => 'pes',
			),
		],
		'statements' => [
			Wikibase::Datatype::Statement->new(
				# IPA transcription (P898)
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'string',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => decode_utf8('pɛs'),
					),
					'property' => 'P898',
				),
			),
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular - Test instance for Wikidata form.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;
 my $grammatical_features_ar = $obj->grammatical_features;
 my $id = $obj->id;
 my $representations_ar = $obj->representations;
 my $statements_ar = $obj->statements;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;

Constructor.

Returns instance of object.

=head2 C<grammatical_features>

 my $grammatical_features_ar = $obj->grammatical_features;

Get grammatical features.

Returns reference to array of Q items.

=head2 C<id>

 my $id = $obj->id;

Get form identifier.

Returns string.

=head2 C<representations>

 my $representations_ar = $obj->representations;

Get representations.

Returns reference to array with Wikibase::Datatype::Value::Monolingual items.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array of Wikibase::Datatype::Statement items.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_form_wd_dogczechsingular.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
 use Unicode::UTF8 qw(encode_utf8);
 use Wikibase::Datatype::Print::Form;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;

 # Print out.
 print encode_utf8(scalar Wikibase::Datatype::Print::Form::print($obj));

 # Output:
 # Id: L469-F1
 # Representation: pes (cs)
 # Grammatical features: Q110786, Q131105
 # Statements:
 #   P898: pɛs (normal)

=head1 DEPENDENCIES

L<Unicode::UTF8>,
L<Wikibase::Datatype::Form>,
L<Wikibase::Datatype::Statement>,
L<Wikibase::Datatype::Snak>,
L<Wikibase::Datatype::Value::Item>,
L<Wikibase::Datatype::Value::Monolingual>,
L<Wikibase::Datatype::Value::String>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Form>

Wikibase form datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.20

=cut
