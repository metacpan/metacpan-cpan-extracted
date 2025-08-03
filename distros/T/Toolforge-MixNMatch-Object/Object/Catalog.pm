package Toolforge::MixNMatch::Object::Catalog;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_required);
use Mo::utils::Array qw(check_array_object);

our $VERSION = 0.04;

has count => (
	is => 'ro',
);

has type => (
	is => 'ro',
);

has year_months => (
	default => [],
	is => 'ro',
);

has users => (
	default => [],
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check require.
	check_required($self, 'count');
	check_required($self, 'type');

	# Check year month.
	check_array_object($self, 'year_months', 'Toolforge::MixNMatch::Object::YearMonth');

	# Check users.
	check_array_object($self, 'users', 'Toolforge::MixNMatch::Object::User');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Object::Catalog - Mix'n'match catalog datatype.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Object::Catalog;

 my $obj = Toolforge::MixNMatch::Object::Catalog->new(%params);
 my $count = $obj->count;
 my $type = $obj->type;
 my $year_months = $obj->year_months;
 my $users = $obj->users;

=head1 DESCRIPTION

This datatype is base class for Mix'n'match catalog.

=head1 METHODS

=head2 C<new>

 my $obj = Toolforge::MixNMatch::Object::Catalog->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<count>

Count number of records in catalog.
Parameter is required.

=item * C<type>

Catalog type in sense of Wikidata instance.
Example is 'Q5' for human.
Parameter is required.

=item * C<year_months>

Year/months statistics.
Reference to array with Toolforge::MixNMatch::Object::YearMonth instances.
Default value is [].

=item * C<users>

Users statistics.
Reference to array with Toolforge::MixNMatch::Object::User instances.
Default value is [].

=back

=head2 C<count>

 my $count = $obj->count;

Get count.

Returns number.

=head2 C<type>

 my $type = $obj->type;

Get type.

Returns string.

=head2 C<year_months>

 my $year_months = $obj->year_months;

Get year/months statistics.

Returns reference to array with Toolforge::MixNMatch::Object::YearMonth
instances.

=head2 C<users>

 my $users = $obj->users;

Get users statistics.

Returns reference to array with Toolforge::MixNMatch::Object::User
instances.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'count' is required.
                 Parameter 'type' is required.

         From Mo::utils::Array::check_array_object():
                 Parameter 'users' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'users' with array must contain 'Toolforge::MixNMatch::Object::Catalog::User' objects.
                         Value: %s
                         Reference: %s
                 Parameter 'year_months' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'year_months' with array must contain 'Toolforge::MixNMatch::Object::Catalog::YearMonth' objects.
                         Value: %s
                         Reference: %s

=head1 EXAMPLE

=for comment filename=create_catalog_and_print_out.pl

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Object::Catalog;
 use Toolforge::MixNMatch::Object::User;
 use Toolforge::MixNMatch::Object::YearMonth;

 # Object.
 my $obj = Toolforge::MixNMatch::Object::Catalog->new(
         'count' => 10,
         'type' => 'Q5',
         'users' => [
                 Toolforge::MixNMatch::Object::User->new(
                         'count' => 6,
                         'uid' => 1,
                         'username' => 'Skim',
                 ),
                 Toolforge::MixNMatch::Object::User->new(
                         'count' => 4,
                         'uid' => 2,
                         'username' => 'Foo',
                 ),
         ],
         'year_months' => [
                 Toolforge::MixNMatch::Object::YearMonth->new(
                         'count' => 2,
                         'month' => 9,
                         'year' => 2020,
                 ),
                 Toolforge::MixNMatch::Object::YearMonth->new(
                         'count' => 8,
                         'month' => 10,
                         'year' => 2020,
                 ),
         ],
 );

 # Get count.
 my $count = $obj->count;

 # Get type.
 my $type = $obj->type;

 # Get year months stats.
 my $year_months_ar = $obj->year_months;

 # Get users.
 my $users_ar = $obj->users;

 # Print out.
 print "Count: $count\n";
 print "Type: $type\n";
 print "Number of month/year statistics: ".(scalar @{$year_months_ar})."\n";
 print "Number of users: ".(scalar @{$users_ar})."\n";

 # Output:
 # Count: 10
 # Type: Q5
 # Number of month/year statistics: 2
 # Number of users: 2

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Array>.

=head1 SEE ALSO

=over

=item L<Toolforge::MixNMatch::Object>

Toolforge Mix'n'match tool objects.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Object>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2025

BSD 2-Clause License

=head1 VERSION

0.04

=cut
