package Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation;

use base qw(Wikibase::Datatype::Value::Item);
use strict;
use warnings;

our $VERSION = 0.29;

sub new {
	my $class = shift;

	my @params = (
		'value' => 'Q3331189',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation - Test instance for Wikidata item value.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation->new;
 my $type = $obj->type;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation->new;

Constructor.

Returns instance of object.

=head2 C<type>

 my $type = $obj->type;

Get type. This is constant 'item'.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_value_item_wd_versioneditionortranslation.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation;
 use Wikibase::Datatype::Print::Value::Item;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Value::Item::print($obj);

 # Output:
 # Q3331189

=head1 DEPENDENCIES

L<Wikibase::Datatype::Value::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Value::Item>

Wikibase item value datatype.

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

0.29

=cut
