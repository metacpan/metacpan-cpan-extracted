#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;

use WWW::Pastebin::PastebinCom::Create;
my $bin = WWW::Pastebin::PastebinCom::Create->new;

my $paste_uri = $bin->paste(
    text    => q{
        use 5.006;
        use strict;
        use warnings FATAL => 'all';
        use Test::More;
    },
    expiry  => 'asap',
    format  => 'perl',
    desc    => 'Perl header',
);

diag "Pasted something. Paste URI is supposedly this: " . (
    defined $paste_uri ? $paste_uri : '[undefined]'
);

SKIP: {
    unless ( $paste_uri ) {
        diag 'Got error while pasting: ' . $bin->error;

        if ( $bin->error =~ /^Network/ ) {
            skip 'Got a network error; skipping', 5;
        }
        elsif ( $bin->error =~ /^Reached the paste limit/ ) {
            skip 'Reached the paste limit; skipping', 5;
        }
    }

    is(
        $paste_uri,
        $bin->paste_uri,
        'return from ->paste matches ->paste_uri',
    );

    is(
        $bin->paste_uri,
        "$bin",
        'return from ->paste_uri matches interpolated object',
    );

    like(
        $paste_uri,
        qr{\Ahttp://pastebin\.com/\w+\z},
        'paste URI looks like a proper paste URI',
    );

    is(
        $bin->paste, # error out on purpose
        undef,
        'errored out ->paste returns undef/empty list',
    );

    is(
        $bin->error,
        'Paste text is empty',
        '->error return an error when it should',
    );
}