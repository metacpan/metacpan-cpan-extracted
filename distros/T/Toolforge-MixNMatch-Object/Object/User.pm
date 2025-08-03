package Toolforge::MixNMatch::Object::User;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);

our $VERSION = 0.04;

has count => (
	is => 'ro',
	required => 1,
);

has uid => (
	is => 'ro',
	required => 1,
);

has username => (
	is => 'ro',
	required => 1,
);

sub BUILD {
	my $self = shift;

	check_required($self, 'count');
	check_required($self, 'uid');
	check_required($self, 'username');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Object::User - Mix'n'match user datatype.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Object::User;

 my $obj = Toolforge::MixNMatch::Object::User->new(%params);
 my $count = $obj->count;
 my $uid = $obj->uid;
 my $username = $obj->username;

=head1 DESCRIPTION

This datatype is base class for Mix'n'match user.

=head1 METHODS

=head2 C<new>

 my $obj = Toolforge::MixNMatch::Object::User->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<count>

Count number of records for user.
Parameter is required.

=item * C<uid>

User UID.
Parameter is required.

=item * C<username>

User name.
Parameter is required.

=back

=head2 C<count>

 my $count = $obj->count;

Get count for user.

Returns number.

=head2 C<uid>

 my $uid = $obj->uid;

Get UID of user.

Returns number.

=head2 C<username>

 my $username = $obj->username;

Get user name.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'count' is required.
                 Parameter 'uid' is required.
                 Parameter 'username' is required.

=head1 EXAMPLE

=for comment filename=create_user_and_print_out.pl

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Object::User;

 # Object.
 my $obj = Toolforge::MixNMatch::Object::User->new(
         'count' => 6,
         'uid' => 1,
         'username' => 'Skim',
 );

 # Get count for user.
 my $count = $obj->count;

 # Get UID of user.
 my $uid = $obj->uid;

 # Get user name.
 my $username = $obj->username;

 # Print out.
 print "Count: $count\n";
 print "UID: $uid\n";
 print "User name: $username\n";

 # Output:
 # Count: 6
 # UID: 1
 # User name: Skim

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

© Michal Josef Špaček 2020-2025

BSD 2-Clause License

=head1 VERSION

0.04

=cut
