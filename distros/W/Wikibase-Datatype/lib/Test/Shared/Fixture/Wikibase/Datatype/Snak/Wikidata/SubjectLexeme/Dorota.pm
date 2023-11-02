package Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota;

use base qw(Wikibase::Datatype::Snak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota;

our $VERSION = 0.33;

sub new {
	my $class = shift;

	my @params = (
		'datatype' => 'wikibase-lexeme',
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota->new,
		'property' => 'P6254',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota - Test instance for Wikidata snak.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SexOrGender::Dorota;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota->new;
 my $datatype = $obj->datatype;
 my $datavalue = $obj->datavalue;
 my $property = $obj->property;
 my $snaktype = $obj->snaktype;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota->new;

Constructor.

Returns instance of object.

=head2 C<datatype>

 my $datatype = $obj->datatype;

Get data type.

Returns string.

=head2 C<datavalue>

 my $datavalue = $obj->datavalue;

Get data value.

Returns instance of Wikibase::Datatype::Value.

=head2 C<property>

 my $property = $obj->property;

Get property name.

Returns string.

=head2 C<snaktype>

 my $snaktype = $obj->snaktype;

Get snak type.

Returns string.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_snak_wd_subject_lexeme_dorota.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota;
 use Wikibase::Datatype::Print::Snak;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Snak::print($obj);

 # Output:
 # P6254: L42284

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota>,
L<Wikibase::Datatype::Snak>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Snak>

Wikibase snak datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2023

BSD 2-Clause License

=head1 VERSION

0.33

=cut
