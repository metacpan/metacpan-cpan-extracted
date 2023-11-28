package WebService::Kramerius::API4::User;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

sub profile {
	my $self = shift;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/user/profile');
}

sub user {
	my $self = shift;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/user');
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Kramerius::API4::User - Class to user endpoint in Kramerius v4+ API.

=head1 SYNOPSIS

 use WebService::Kramerius::API4::User;

 my $obj = WebService::Kramerius::API4::User->new(%params);
 my $profile = $obj->profile;
 my $user = $obj->user;

=head1 METHODS

=head2 C<new>

 my $obj = WebService::Kramerius::API4::User->new(%params);

Constructor.

=over 8

=item * C<library_url>

Library URL.

This parameter is required.

Default value is undef.

=item * C<output_dispatch>

Output dispatch hash structure.
Key is content-type and value is subroutine, which converts content to what do you want.

Default value is blank hash array.

=back

Returns instance of object.

=head2 C<profile>

 my $profile = $obj->profile;

Get user profile from Kramerius system.

Returns string with JSON.

=head2 C<user>

 my $user = $obj->user;

Get user from Kramerius system.

Returns string with JSON.

=head1 ERRORS

 new():
         Parameter 'library_url' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

=for comment filename=kramerius_user_profile.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::User;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 library_url\n";
         exit 1;
 }
 my $library_url = $ARGV[0];

 my $obj = WebService::Kramerius::API4::User->new(
         'library_url' => $library_url,
 );

 my $profile_json = $obj->profile;

 print $profile_json."\n";

 # Output for 'http://kramerius.mzk.cz/', pretty print.
 # {}

=head1 EXAMPLE2

=for comment filename=kramerius_user_user.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::User;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 library_url\n";
         exit 1;
 }
 my $library_url = $ARGV[0];

 my $obj = WebService::Kramerius::API4::User->new(
         'library_url' => $library_url,
 );

 my $user_json = $obj->user;

 print $user_json."\n";

 # Output for 'http://kramerius.mzk.cz/', pretty print.
 # {
 #   "lname": "not_logged",
 #   "firstname": "not_logged",
 #   "surname": "not_logged",
 #   "session": {},
 #   "roles": [
 #     {
 #       "name": "common_users",
 #       "id": 1
 #     }
 #   ],
 #   "id": -1,
 #   "labels": []
 # }

=head1 DEPENDENCIES

L<WebService::Kramerius::API4::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WebService-Kramerius-API4>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2015-2023

BSD 2-Clause License

=head1 VERSION

0.02

=cut
