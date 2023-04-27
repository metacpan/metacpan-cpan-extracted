package Wikibase::Datatype::Reference;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils qw(check_array_object check_required);

our $VERSION = 0.31;

has snaks => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	check_required($self, 'snaks');

	check_array_object($self, 'snaks', 'Wikibase::Datatype::Snak', 'Snak');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Reference - Wikibase reference datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Reference;

 my $obj = Wikibase::Datatype::Reference->new(%params);
 my $snaks_ar = $obj->snaks;

=head1 DESCRIPTION

This datatype is reference class for all references in claim.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Reference->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<snaks>

Reference to array with Wikibase::Datatype::Snak instances.
Parameter is required.

=back

=head2 C<snaks>

 my $snaks_ar = $obj->snaks;

Get snaks.

Returns reference to array of Wikibase::Datatype::Snak instances.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Parameter 'snaks' must be a array.
                 Snak isn't 'Wikibase::Datatype::Snak' object.
         From Mo::utils::check_required():
                 Parameter 'snaks' is required.

=head1 EXAMPLE

=for comment filename=create_and_print_reference.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Reference->new(
         'snaks' => [
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'url',
                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                 'value' => 'https://skim.cz',
                         ),
                         'property' => 'P854',
                 ),
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'time',
                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                 'value' => '+2013-12-07T00:00:00Z',
                         ),
                         'property' => 'P813',
                 ),
         ],
 );

 # Get value.
 my $snaks_ar = $obj->snaks;

 # Print out number of snaks.
 print "Number of snaks: ".@{$snaks_ar}."\n";

 # Output:
 # Number of snaks: 2

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Mo::utils>.

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

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.31

=cut
