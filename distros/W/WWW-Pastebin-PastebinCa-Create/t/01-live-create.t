#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('pastebin.ca' => 443);
use WWW::Pastebin::PastebinCa::Create;

my $paster = WWW::Pastebin::PastebinCa::Create->new( timeout => 30 );

my $content = "WWW::Pastebin::PastebinCa::Create live test\n"
            . "value: 12345\n";

my $uri = $paster->paste(
    $content,
    name   => 'cpan-live-test',
    lang   => 6,             # perl
    expire => '5 minutes',
);

unless ( defined $uri ) {
    plan skip_all => 'Could not create paste: ' . $paster->error;
}

isa_ok( $uri, 'URI::http', 'paste() returns a URI object' );
like( "$uri", qr{^https?://pastebin\.ca/\w+$},
    'uri points at a pastebin.ca paste' );
is( "$uri", "" . $paster->paste_uri,
    '->paste_uri and return from ->paste() must match' );
is( "$paster", "$uri", 'object interpolates to the paste uri' );

# Verify the paste really exists by reading its stored body back through the
# public API.
my ( $id ) = "$uri" =~ m{pastebin\.ca/(\w+)};
ok( length $id, "extracted paste id ($id)" );

my $res = $paster->mech->get("https://pastebin.ca/api/v1/pastes/$id");
SKIP: {
    skip 'Could not fetch created paste back: ' . $res->status_line, 1
        unless $res->is_success;
    my $data = eval { JSON::PP->new->utf8->decode( $res->decoded_content ) };
    is( ref $data eq 'HASH' ? $data->{body} : undef, $content,
        'stored paste body matches what we submitted' );
}

done_testing();
