use strict;
use warnings;

use Test::More;
use LWP::Simple 'get';
use JSON;
use Data::Dumper;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my %post_types = (
    text    => { body => scalar localtime() },
    photo   => { source => 'http://lorempixel.com/400/200/' },
    quote   => { quote => decode_json( get 'http://quotesondesign.com/api/3.0/api-3.0.json' )->{quote} },
    link    => do {
        eval {
            my ( $author, $release) = @{ decode_json( get("http://api.metacpan.org/v0/favorite/_search?size=50&fields=author,release&sort=date:desc") )->{hits}->{hits}->[ int rand 50 ]->{fields} }{'author', 'release'};
            { url => "http://metacpan.org/release/$author/$release" }
        } or do {
            { url => "https://damog.net/blog" }
        };
    },
);

# TODO: chat, audio, video

my $blog = WWW::Tumblr::Test::blog();

for my $type ( sort keys %post_types ) {
    ok $blog->post( type => $type, %{ $post_types{ $type } } ),       "trying $type";
}


done_testing();
