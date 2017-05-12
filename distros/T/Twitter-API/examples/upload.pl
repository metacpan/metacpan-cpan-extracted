#!/usr/bin/env perl
use 5.14.1;
use warnings;

use Twitter::API;

my $client = Twitter::API->new_with_traits(
    traits => [ qw/ApiMethods/ ],
    consumer_key        => $ENV{CONSUMER_KEY},
    consumer_secret     => $ENV{CONSUMER_SECRET},
    access_token        => $ENV{ACCESS_TOKEN},
    access_token_secret => $ENV{ACCESS_TOKEN_SECRET},
);

my $r = $client->upload_media([ "$ENV{HOME}/Downloads/hello-world.png" ]);

say "media_id: $$r{media_id}";
