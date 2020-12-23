package Toolforge::MixNMatch::Print::Catalog;

use strict;
use warnings;

use Error::Pure qw(err);
use Indent;
use Toolforge::MixNMatch::Print::User;
use Toolforge::MixNMatch::Print::YearMonth;

our $VERSION = 0.04;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Toolforge::MixNMatch::Object::Catalog')) {
		err "Object isn't 'Toolforge::MixNMatch::Object::Catalog'.";
	}

	if (! defined $opts_hr) {
		$opts_hr = {
			'type' => 1,
			'count' => 1,
			'year_months' => 1,
			'users' => 1,
		};
	}

	my @print = (
		$opts_hr->{'type'} ? 'Type: '.$obj->type : (),
		$opts_hr->{'count'} ? 'Count: '.$obj->count : (),
	);

	my $i;

	if ($opts_hr->{'year_months'} && @{$obj->year_months}) {
		$i //= Indent->new;
		push @print, 'Year/months:';
		$i->add;
		foreach my $year_month (sort { $a->year <=> $b->year || $a->month <=> $b->month }
			@{$obj->year_months}) {

			push @print, $i->get.Toolforge::MixNMatch::Print::YearMonth::print($year_month);
		}
		$i->remove;
	}

	if ($opts_hr->{'users'} && @{$obj->users}) {
		$i //= Indent->new;
		push @print, 'Users:';
		$i->add;
		foreach my $user (reverse sort { $a->count <=> $b->count } @{$obj->users}) {
			push @print, $i->get.Toolforge::MixNMatch::Print::User::print($user);
		}
		$i->remove;
	}

	return wantarray ? @print : (join "\n", @print);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Print::Catalog - Mix'n'match catalog structure print.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Print::Catalog qw(print);

 my $print = print($obj);

=head1 SUBROUTINES

=head2 C<print>

 my $print = print($obj);

Print Toolforge::MixNMatch::Object::Catalog instance to user output.

Returns string.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Toolforge::MixNMatch::Object::Catalog'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Printer;
 use Toolforge::MixNMatch::Object::Catalog;
 use Toolforge::MixNMatch::Object::User;
 use Toolforge::MixNMatch::Object::YearMonth;
 use Toolforge::MixNMatch::Print::Catalog;

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

 # Print.
 print Toolforge::MixNMatch::Print::Catalog::print($obj)."\n";

 # Output:
 # Type: Q5
 # Count: 10
 # Year/months:
 #         2020/9: 2
 #         2020/10: 8
 # Users:
 #         Skim (1): 6
 #         Foo (2): 4

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
