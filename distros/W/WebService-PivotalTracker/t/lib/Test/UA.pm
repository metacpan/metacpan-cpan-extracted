package Test::UA;

use strict;
use warnings;

use Digest::MD5 qw( md5_hex );
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

            my $unescaped = uri_unescape($path);
            for my $file ( map { path( 't/fixtures', $_ . '.json' ) }
                $unescaped, md5_hex($unescaped) ) {

                next unless $file->exists;

                return HTTP::Response->new(
                    200,
                    undef,
                    [ 'Content-Type' => 'application/json' ],
                    scalar $file->slurp,
                );
            }

            return HTTP::Response->new(404);
        }
    );
    return $ua;
}

1;
