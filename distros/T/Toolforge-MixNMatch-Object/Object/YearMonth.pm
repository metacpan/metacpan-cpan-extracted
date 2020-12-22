package Toolforge::MixNMatch::Object::YearMonth;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);

our $VERSION = 0.03;

has count => (
	is => 'ro',
	required => 1,
);

has month => (
	is => 'ro',
	required => 1,
);

has year => (
	is => 'ro',
	required => 1,
);

sub BUILD {
	my $self = shift;

	check_required($self, 'count');
	check_required($self, 'month');
	check_required($self, 'year');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Object::YearMonth - Mix'n'match year/month datatype.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Object::YearMonth;

 my $obj = Toolforge::MixNMatch::Object::YearMonth->new(%params);
 my $count = $obj->count;
 my $month = $obj->month;
 my $year = $obj->year;

=head1 DESCRIPTION

This datatype is base class for Mix'n'match year/month.

=head1 METHODS

=head2 C<new>

 my $obj = Toolforge::MixNMatch::Object::YearMonth->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<count>

Count number of records for user.
Parameter is required.

=item * C<month>

Month of statistics.
Parameter is required.

=item * C<year>

Year of statistics.
Parameter is required.

=back

=head2 C<count>

 my $count = $obj->count;

Get count for year/month statistics.

Returns number.

=head2 C<month>

 my $month = $obj->month;

Get month of statistics.

Returns number.

=head2 C<year>

 my $year = $obj->year;

Get year of statistics.

Returns number.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'count' is required.
                 Parameter 'month' is required.
                 Parameter 'year' is required.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Object::YearMonth;

 # Object.
 my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
         'count' => 6,
         'month' => 1,
         'year' => 2020,
 );

 # Get count for year/month statistics.
 my $count = $obj->count;

 # Get month of statistics.
 my $month = $obj->month;

 # Get year of statistics.
 my $year = $obj->year;

 # Print out.
 print "Count: $count\n";
 print "Month: $month\n";
 print "Year: $year\n";

 # Output:
 # Count: 6
 # Month: 1
 # Year: 2020

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

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

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.03

=cut
