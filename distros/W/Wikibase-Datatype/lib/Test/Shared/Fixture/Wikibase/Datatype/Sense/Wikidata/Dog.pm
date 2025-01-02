package Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;

use base qw(Wikibase::Datatype::Sense);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.36;

sub new {
	my $class = shift;

	my @params = (
		'glosses' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'domesticated mammal related to the wolf',
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
			),
		],
		# https://www.wikidata.org/wiki/Lexeme:L469
		'id' => 'L469-S1',
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog->new,
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

Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog - Test instance for Wikidata sense.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new;
 my $glosses_ar = $obj->glosses;
 my $id = $obj->id;
 my $statements_ar = $obj->statements;

=head1 DESCRIPTION

This datatype is snak class for representing relation between property and value.

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new;

Constructor.

Returns instance of object.

=head2 C<glosses>

 my $glosses_ar = $obj->glosses;

Get glosses.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array with Wikibase::Datatype::Statement instances.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_sense_wd_dog.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;
 use Unicode::UTF8 qw(encode_utf8);
 use Wikibase::Datatype::Print::Sense;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new;

 # Print out.
 print encode_utf8(scalar Wikibase::Datatype::Print::Sense::print($obj));

 # Output:
 # Id: L469-S1
 # Glosses:
 #   domesticated mammal related to the wolf (en)
 #   psovitá šelma chovaná jako domácí zvíře (cs)
 # Statements:
 #   P18: Canadian Inuit Dog.jpg (normal)
 #   P5137: Q144 (normal)

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog>,
L<Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog>,
L<Unicode::UTF8>,
L<Wikibase::Datatype::Sense>,
L<Wikibase::Datatype::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Sense>

Wikibase sense datatype.

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

0.36

=cut
