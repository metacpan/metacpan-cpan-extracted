package Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;

use base qw(Wikibase::Datatype::Reference);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;

our $VERSION = 0.26;

sub new {
	my $class = shift;

	my @params = (
		'snaks' => [
			# reference URL (P854) https://skim.cz
			Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1->new,

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

Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL - Test instance for Wikidata reference.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL->new;
 my $snaks_ar = $obj->snaks;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL->new;

Constructor.

Returns instance of object.

=head2 C<snaks>

 my $snaks_ar = $obj->snaks;

Get snaks.

Returns reference to array of Wikibase::Datatype::Snak instances.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_reference_wd_url.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;
 use Wikibase::Datatype::Print::Reference;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Reference::print($obj);

 # Output:
 # {
 #   P854: https://skim.cz
 #   P813: 07 December 2013 (Q1985727)
 # }

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1>,
L<Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1>,
L<Wikibase::Datatype::Reference>.

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

0.26

=cut
