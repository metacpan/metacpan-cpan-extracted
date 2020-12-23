package Toolforge::MixNMatch::Print::YearMonth;

use strict;
use warnings;

use Error::Pure qw(err);

our $VERSION = 0.04;

sub print {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Toolforge::MixNMatch::Object::YearMonth')) {
		err "Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.";
	}

	my $print = $obj->year.'/'.$obj->month.': '.$obj->count;

	return $print;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Print::YearMonth - Mix'n'match year/month structure print.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Print::YearMonth qw(print);

 my $print = print($obj);

=head1 SUBROUTINES

=head2 C<print>

 my $print = print($obj);

Print Toolforge::MixNMatch::Object::YearMonth instance to user output.

Returns string.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Printer;
 use Toolforge::MixNMatch::Object::YearMonth;
 use Toolforge::MixNMatch::Print::YearMonth;

 # Object.
 my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
         'count' => 6,
         'month' => 9,
         'year' => 2020,
 );

 # Print.
 print Toolforge::MixNMatch::Print::YearMonth::print($obj)."\n";

 # Output:
 # 2020/9: 6

=head1 DEPENDENCIES

L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Toolforge::MixNMatch::Print>

Toolforge Mix'n'match tool object print routines.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.04

=cut
