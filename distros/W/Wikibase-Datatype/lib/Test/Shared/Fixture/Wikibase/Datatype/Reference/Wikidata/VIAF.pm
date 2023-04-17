package Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;

use base qw(Wikibase::Datatype::Reference);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

our $VERSION = 0.25;

sub new {
	my $class = shift;

	my @params = (
		'snaks' => [
			# stated in (P248) Virtual International Authority File (Q53919)
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF->new,

			# VIAF ID (P214) 113230702
			Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => '113230702',
				),
				'property' => 'P214',
			),

			# retrieved (P813) 7 December 2013
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1->new,
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

Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF - Test instance for Wikidata reference.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF->new;
 my $snaks_ar = $obj->snaks;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF->new;

Constructor.

Returns instance of object.

=head2 C<snaks>

 my $snaks_ar = $obj->snaks;

Get snaks.

Returns reference to array of Wikibase::Datatype::Snak instances.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_reference_wd_viaf.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;
 use Wikibase::Datatype::Print::Reference;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Reference::print($obj);

 # Output:
 # {
 #   P248: Q53919
 #   P214: 113230702
 #   P813: 07 December 2013 (Q1985727)
 # }

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1>,
L<Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF>,
L<Wikibase::Datatype::Reference>,
L<Wikibase::Datatype::Snak>,
L<Wikibase::Datatype::Value::Item>,
L<Wikibase::Datatype::Value::String>,
L<Wikibase::Datatype::Value::Time>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Reference>

Wikibase reference value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.25

=cut
