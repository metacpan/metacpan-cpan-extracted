package Toolforge::MixNMatch::Diff;

use strict;
use warnings;

use Error::Pure qw(err);
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Object::YearMonth;

our $VERSION = 0.02;

sub diff {
	my ($catalog1, $catalog2, $warn) = @_;

	$warn //= 0;

	if ($catalog1->type ne $catalog2->type) {
		_warn('Different type of catalogs.', $warn);
	}

	if ($catalog1->count != $catalog2->count) {
		_warn('Count values of catalogs are different.', $warn);
	}

	my ($new_cat, $old_cat) = _which_catalog_is_new($catalog1, $catalog2, $warn);

	# Diff of users.
	my $users_ar = [];
	foreach my $new_cat_user (@{$new_cat->users}) {
		my $old_cat_user;
		foreach my $user_iter (@{$old_cat->users}) {
			if ($user_iter->username eq $new_cat_user->username) {

				if ($user_iter->uid ne $new_cat_user->uid) {
					err 'Something wrong with uids in catalogs.';
				}
				$old_cat_user = $user_iter;
				last;
			}
		}
		my $count = defined $old_cat_user ? 
			($new_cat_user->count - $old_cat_user->count)
			: $new_cat_user->count;
		if ($count) {
			push @{$users_ar}, Toolforge::MixNMatch::Object::User->new(
				'count' => $count,
				'uid' => $new_cat_user->uid,
				'username' => $new_cat_user->username,
			);
		}
	}

	# Diff of dates.
	my $year_months_ar = [];
	foreach my $new_cat_year_month (sort { $a->year <=> $b->year || $a->month <=> $b->month }
		@{$new_cat->year_months}) {

		my $old_cat_year_month;
		foreach my $year_month_iter (@{$old_cat->year_months}) {
			if ($year_month_iter->year eq $new_cat_year_month->year
				&& $year_month_iter->month eq $new_cat_year_month->month) {

				$old_cat_year_month = $year_month_iter;
				last;
			}
		}
		my $count = defined $old_cat_year_month ?
			($new_cat_year_month->count - $old_cat_year_month->count)
			: $new_cat_year_month->count;
		if ($count) {
			push @{$year_months_ar}, Toolforge::MixNMatch::Object::YearMonth->new(
				'year' => $new_cat_year_month->year,
				'month' => $new_cat_year_month->month,
				'count' => $count,
			);
		}
	}

	my $catalog_diff = Toolforge::MixNMatch::Object::Catalog->new(
		'count' => $new_cat->count,
		'type' => $new_cat->type,
		'users' => $users_ar,
		'year_months' => $year_months_ar,
	);

	return $catalog_diff;
}

sub _compute_users_count {
	my $catalog = shift;

	my $count = 0;
	foreach my $user (@{$catalog->users}) {
		$count += $user->count;
	}

	return $count;
}

sub _warn {
	my ($mess, $warn) = @_;

	if ($warn) {
		print "WARNING: $mess\n";
	}

	return;
}

sub _which_catalog_is_new {
	my ($catalog1, $catalog2, $warn) = @_;

	my ($new_cat, $old_cat);

	# Different total counts.
	if ($catalog1->count > $catalog2->count) {
		$new_cat = $catalog1;
		$old_cat = $catalog2;
	} elsif ($catalog2->count > $catalog1->count) {
		$new_cat = $catalog2;
		$old_cat = $catalog1;

	# Total counts are same.
	} else {
		my $users_count1 = _compute_users_count($catalog1);
		my $users_count2 = _compute_users_count($catalog2);
		if ($users_count1 > $users_count2) {
			$new_cat = $catalog1;
			$old_cat = $catalog2;
		} elsif ($users_count2 > $users_count1) {
			$new_cat = $catalog2;
			$old_cat = $catalog1;

		# All counts are same.
		} else {
			_warn('Catalogs are same in counts.', $warn);
			$new_cat = $catalog2;
			$old_cat = $catalog1;
		}
	}

	return ($new_cat, $old_cat);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Diff - Mix'n'match catalogs diff.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Diff;

 my $diff_cat = Toolforge::MixNMatch::Diff::diff($cat1, $cat2, $warn);

=head1 SUBRUTINES

=head2 C<diff>

 my $diff_cat = Toolforge::MixNMatch::Diff::diff($cat1, $cat2, $warn);

Creates diff between two catalogs.
C<$warn> is boolean variable which turn on/off warnings (default is off).

Returns instance of Toolforge::MixNMatch::Object::Catalog.

=head1 ERRORS

 diff():
         Something wrong with uids in catalogs.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Diff;
 use Toolforge::MixNMatch::Object::Catalog;
 use Toolforge::MixNMatch::Object::User;
 use Toolforge::MixNMatch::Object::YearMonth;
 use Toolforge::MixNMatch::Print::Catalog;

 # Catalogs.
 my $cat1 = Toolforge::MixNMatch::Object::Catalog->new(
         'count' => 10,
         'type' => 'Q5',
         'users' => [
                 Toolforge::MixNMatch::Object::User->new(
                         'count' => 2,
                         'uid' => 1,
                         'username' => 'Skim',
                 ),
                 Toolforge::MixNMatch::Object::User->new(
                         'count' => 1,
                         'uid' => 2,
                         'username' => 'Foo',
                 ),
         ],
         'year_months' => [
                 Toolforge::MixNMatch::Object::YearMonth->new(
                         'count' => 3,
                         'month' => 9,
                         'year' => 2020,
                 ),
         ],
 );
 my $cat2 = Toolforge::MixNMatch::Object::Catalog->new(
         'count' => 10,
         'type' => 'Q5',
         'users' => [
                 Toolforge::MixNMatch::Object::User->new(
                         'count' => 3,
                         'uid' => 1,
                         'username' => 'Skim',
                 ),
                 Toolforge::MixNMatch::Object::User->new(
                         'count' => 2,
                         'uid' => 2,
                         'username' => 'Foo',
                 ),
         ],
         'year_months' => [
                 Toolforge::MixNMatch::Object::YearMonth->new(
                         'count' => 3,
                         'month' => 9,
                         'year' => 2020,
                 ),
                 Toolforge::MixNMatch::Object::YearMonth->new(
                         'count' => 2,
                         'month' => 10,
                         'year' => 2020,
                 ),
         ],
 );

 my $diff_cat = Toolforge::MixNMatch::Diff::diff($cat1, $cat2);

 # Print out.
 print "Catalog #1:\n";
 print Toolforge::MixNMatch::Print::Catalog::print($cat1)."\n\n";
 print "Catalog #2:\n";
 print Toolforge::MixNMatch::Print::Catalog::print($cat2)."\n\n";
 print "Diff catalog:\n";
 print Toolforge::MixNMatch::Print::Catalog::print($diff_cat)."\n";

 # Output:
 # Catalog #1:
 # Type: Q5
 # Count: 10
 # Year/months:
 #         2020/9: 3
 # Users:
 #         Skim (1): 2
 #         Foo (2): 1
 # 
 # Catalog #2:
 # Type: Q5
 # Count: 10
 # Year/months:
 #         2020/9: 3
 #         2020/10: 2
 # Users:
 #         Skim (1): 3
 #         Foo (2): 2
 # 
 # Diff catalog:
 # Type: Q5
 # Count: 10
 # Year/months:
 #         2020/10: 2
 # Users:
 #         Foo (2): 1
 #         Skim (1): 1

=head1 DEPENDENCIES

L<Error::Pure>,
L<Toolforge::MixNMatch::Object::Catalog>,
L<Toolforge::MixNMatch::Object::User>,
L<Toolforge::MixNMatch::Object::YearMonth>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Diff>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.04

=cut
