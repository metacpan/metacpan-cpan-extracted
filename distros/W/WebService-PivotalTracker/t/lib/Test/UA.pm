package Test::UA;

use strict;
use warnings;

use HTTP::Response;
use Path::Tiny qw( path );
use Test2::Bundle::Extended;
use Test::LWP::UserAgent;
use URI::Escape qw( uri_unescape );

use Exporter qw( import );
our @EXPORT_OK = 'ua';

sub ua {
    my $ua = Test::LWP::UserAgent->new( network_fallback => 0 );
    $ua->map_response(
        sub {
            return 1;
        },
        sub {
            my $req = shift;

            my $path = $req->uri->path_query;

            my $file = path( 't/fixtures', uri_unescape($path) . '.json' );

            return HTTP::Response->new(404)
                unless $file->exists;

            return HTTP::Response->new(
                200,
                undef,
                [ 'Content-Type' => 'application/json' ],
                scalar $file->slurp,
            );
        }
    );
    return $ua;
}

1;
