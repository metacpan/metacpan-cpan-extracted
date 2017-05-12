package WWW::Stickam::API::Search::Media;

use strict;
use warnings;
use base qw/WWW::Stickam::API::Base/;

sub uri {
    my $uri = "http://api.stickam.com/api/search/media";
}

1;

=head1 NAME

WWW::Stickam::API::Search::Media - Search/Media API

=head1 SYNOPSYS

 my $api = WWW::Stickam::API->new();
 if( $api->call('Search/Media' , { type=>'video' , text="Welcome to Stickam"  } ) ) {
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

http://labs.stickam.jp/api/#media-search

=head1 AUTHOR

Tomohiro Teranishi<tomohiro.teranishi@gmail.com>

=cut
