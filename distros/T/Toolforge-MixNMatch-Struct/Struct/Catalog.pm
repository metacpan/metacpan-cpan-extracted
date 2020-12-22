package Toolforge::MixNMatch::Struct::Catalog;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Struct::User;
use Toolforge::MixNMatch::Struct::YearMonth;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.04;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Toolforge::MixNMatch::Object::Catalog')) {
		err "Object isn't 'Toolforge::MixNMatch::Object::Catalog'.";
	}

	my $struct_hr = {
		'type' => [{
			'type' => $obj->type,
			'cnt' => $obj->count,
		}],
		'user' => [],
		'ym' => [],
	};
	foreach my $year_month (@{$obj->year_months}) {
		push @{$struct_hr->{'ym'}},
			Toolforge::MixNMatch::Struct::YearMonth::obj2struct($year_month);
	}
	foreach my $user (@{$obj->users}) {
		push @{$struct_hr->{'user'}},
			Toolforge::MixNMatch::Struct::User::obj2struct($user);
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my $year_months = [];
	foreach my $year_month_hr (@{$struct_hr->{'ym'}}) {
		push @{$year_months}, Toolforge::MixNMatch::Struct::YearMonth::struct2obj($year_month_hr);
	}
	my $users = [];
	foreach my $user_hr (@{$struct_hr->{'user'}}) {
		push @{$users}, Toolforge::MixNMatch::Struct::User::struct2obj($user_hr);
	}
	my $obj = Toolforge::MixNMatch::Object::Catalog->new(
		'count' => $struct_hr->{'type'}->[0]->{'cnt'},
		'type' => $struct_hr->{'type'}->[0]->{'type'},
		'users' => $users,
		'year_months' => $year_months,
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Struct::Catalog - Mix'n'match catalog structure serialization.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Struct::Catalog qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between object defined in Toolforge::MixNMatch::Object::Catalog and structure
serialized via JSON to Mix'n'match application.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Toolforge::MixNMatch::Object::Catalog instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of time to object.

Returns Toolforge::MixNMatch::Object::Catalog instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Toolforge::MixNMatch::Object::Catalog'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Toolforge::MixNMatch::Object::Catalog;
 use Toolforge::MixNMatch::Struct::Catalog qw(obj2struct);

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

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type   [
 #         [0] {
 #             cnt    10,
 #             type   "Q5"
 #         }
 #     ],
 #     user   [
 #         [0] {
 #             cnt        6,
 #             uid        1,
 #             username   "Skim"
 #         },
 #         [1] {
 #             cnt        4,
 #             uid        2,
 #             username   "Foo"
 #         }
 #     ],
 #     ym     [
 #         [0] {
 #             cnt   2,
 #             ym    202009
 #         },
 #         [1] {
 #             cnt   8,
 #             ym    202010
 #         }
 #     ]
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Struct::Catalog qw(struct2obj);

 # Time structure.
 my $struct_hr = {
         'user' => [{
                 'cnt' => 6,
                 'uid' => 1,
                 'username' => 'Skim',
         }, {
                 'cnt' => 4,
                 'uid' => 2,
                 'username' => 'Foo',
         }],
         'type' => [{
                 'cnt' => 10,
                 'type' => 'Q5',
         }],
         'ym' => [{
                 'cnt' => 2,
                 'ym' => 202009,
         }, {
                 'cnt' => 8,
                 'ym' => 202010,
         }],
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get count.
 my $count = $obj->count;

 # Get type.
 my $type = $obj->type;

 # Get user statistics.
 my $users_ar = $obj->users;

 # Get year/month statistics.
 my $year_months_ar = $obj->year_months;

 # Print out.
 print "Count: $count\n";
 print "Type: $type\n";
 print "Count of users: ".(scalar @{$users_ar})."\n";
 print "Count of year/months: ".(scalar @{$year_months_ar})."\n";

 # Output:
 # Count: 10
 # Type: Q5
 # Count of users: 2
 # Count of year/months: 2

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Toolforge::MixNMatch::Object::Catalog>,
L<Toolforge::MixNMatch::Struct::User>,
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
