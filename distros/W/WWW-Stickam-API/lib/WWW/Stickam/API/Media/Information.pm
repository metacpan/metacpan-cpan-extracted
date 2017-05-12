package WWW::Stickam::API::Media::Information;

use strict;
use warnings;
use base qw/WWW::Stickam::API::Base/;

sub uri {
    my $s     = shift;
    my $args  = shift;
    my $media_id = $args->{media_id};
    die 'You must set media_id' unless $media_id;
    delete $args->{media_id};
    my $uri = "http://api.stickam.com/api/media/$media_id/";
}

1;

=head1 NAME

WWW::Stickam::API::Media::Information - Media/Information API

=head1 SYNOPSYS

 my $api = WWW::Stickam::API->new();
 if( $api->call('Media/Information' , { media_id => 170159586 } ) ) {
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

http://labs.stickam.jp/api/#media-information

=head1 AUTHOR

Tomohiro Teranishi<tomohiro.teranishi@gmail.com>

=cut
