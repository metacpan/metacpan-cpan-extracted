package Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;

use base qw(Wikibase::Datatype::MediainfoSnak);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams;

our $VERSION = 0.39;

sub new {
	my $class = shift;

	my @params = (
		'datavalue' => Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams->new,
		'property' => 'P180',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human - Test instance for Wikimedia Commons mediainfo snak.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new(%params);
 my $datavalue = $obj->datavalue;
 my $property = $obj->property;
 my $snaktype = $obj->snaktype;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new(%params);

Constructor.

Returns instance of object.

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

=for comment filename=fixture_create_and_print_mediainfo_snak_commons_depicts_human.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;
 use Wikibase::Datatype::Print::MediainfoSnak;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::MediainfoSnak::print($obj);

 # Output:
 # P180: Q42

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams>,
L<Wikibase::Datatype::MediainfoSnak>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::MediainfoSnak>

Wikibase mediainfo snak datatype.

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
