package WWW::Stickam::API::User::Profile;

use strict;
use warnings;
use base qw/WWW::Stickam::API::Base/;

sub uri {
    my $s     = shift;
    my $args  = shift;
    my $user_name = $args->{user_name};
    die 'You must set user name ' unless $user_name;
    delete $args->{user_name};
    my $uri = "http://api.stickam.com/api/user/$user_name/profile/";
}

1;

=head1 NAME

WWW::Stickam::API::User::Profile - User/Profile API

=head1 SYNOPSYS

 my $api = WWW::Stickam::API->new();
 if( $api->call('User/Profile' , { user_name => 'stickam' } ) ) {
    print Dumper $api->get();
    print $api->get_XML();
    print $api->get_JSON();
 }
 else {
    print $api->error ;
 }

=head1 METHOD

=head2 uri

=head1 SEE ALSO

http://labs.stickam.jp/api/#user-profile

=head1 AUTHOR

Tomohiro Teranishi<tomohiro.teranishi@gmail.com>

=cut
