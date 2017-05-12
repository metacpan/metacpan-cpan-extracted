package WWW::Stickam::API::Search::User;

use strict;
use warnings;
use base qw/WWW::Stickam::API::Base/;

sub uri {
    my $s    = shift;
    my $args = shift;
    my $uri  = "http://api.stickam.com/api/search/user";
}


1;

=head1 NAME

WWW::Stickam::API::Search::User - Search/User API

=head1 SYNOPSYS

 my $api = WWW::Stickam::API->new();
 if( $api->call('Search/User' , { name=>'stickam' } ) ) {
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

http://labs.stickam.jp/api/#user-search

=head1 AUTHOR

Tomohiro Teranishi<tomohiro.teranishi@gmail.com>

=cut
