package Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem;

use base qw(Wikibase::Datatype::Value::Item);
use strict;
use warnings;

our $VERSION = 0.16;

sub new {
	my $class = shift;

	my @params = (
		'value' => 'Q5185279',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem - Test instance for Wikidata item value.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem->new;
 my $type = $obj->type;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem->new;

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

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem;
 use Wikibase::Datatype::Print::Value::Item;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem->new;

 # Print out.
 print scalar Wikibase::Datatype::Print::Value::Item::print($obj);

 # Output:
 # Q5185279

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

© Michal Josef Špaček 2020-2022

BSD 2-Clause License

=head1 VERSION

0.16

=cut
