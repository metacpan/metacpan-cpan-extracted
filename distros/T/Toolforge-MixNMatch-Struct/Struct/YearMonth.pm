package Toolforge::MixNMatch::Struct::YearMonth;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Toolforge::MixNMatch::Object::YearMonth;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.04;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Toolforge::MixNMatch::Object::YearMonth')) {
		err "Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.";
	}

	my $struct_hr = {
		'cnt' => $obj->count,
		'ym' => $obj->year.(sprintf '%02d', $obj->month),
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my ($year, $month) = $struct_hr->{'ym'} =~ m/^(\d{4})(\d{2})$/ms;
	my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
		'count' => $struct_hr->{'cnt'},
		'month' => int($month),
		'year' => $year,
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Struct::YearMonth - Mix'n'match year/month structure serialization.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Struct::YearMonth qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between object defined in Toolforge::MixNMatch::Object::YearMonth and structure
serialized via JSON to Mix'n'match application.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Toolforge::MixNMatch::Object::YearMonth instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of time to object.

Returns Toolforge::MixNMatch::Object::YearMonth instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Toolforge::MixNMatch::Object::YearMonth;
 use Toolforge::MixNMatch::Struct::YearMonth qw(obj2struct);

 # Object.
 my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
         'count' => 6,
         'month' => 9,
         'year' => 2020,
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     cnt   6,
 #     ym    202009
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Struct::YearMonth qw(struct2obj);

 # Time structure.
 my $struct_hr = {
        'cnt' => 6,
        'ym' => 202009,
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get count.
 my $count = $obj->count;

 # Get month.
 my $month = $obj->month;

 # Get year.
 my $year = $obj->year;

 # Print out.
 print "Count: $count\n";
 print "Month: $month\n";
 print "Year: $year\n";

 # Output:
 # Count: 6
 # Month: 9
 # Year: 2020

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Toolforge::MixNMatch::Struct::YearMonth>.

=head1 SEE ALSO

=over

=item L<Toolforge::MixNMatch::Struct>

Toolforge Mix'n'match tool structures.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.04

=cut
