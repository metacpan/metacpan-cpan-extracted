#!/usr/bin/env perl

use Test::More tests => 11;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('WWW::Mechanize');
    use_ok( 'WWW::Pastebin::PastebinCa::Create' );
}

diag( "Testing WWW::Pastebin::PastebinCa::Create $WWW::Pastebin::PastebinCa::Create::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::PastebinCa::Create->new;

isa_ok( $o, 'WWW::Pastebin::PastebinCa::Create');
can_ok( $o, qw(new paste_uri error mech paste valid_langs valid_expires
                    _set_error));

isa_ok( $o->mech, 'WWW::Mechanize');

my $uri = $o->paste('{ map { $_ => $_ } split /,/, $foos ',
expire => '5 minutes' );

if ( not defined $uri ) {
    diag "Got error: " . $o->error;
    ok( (defined $o->error and length $o->error), 'error must be defined' );
    ok( (not defined $o->paste_uri), '->paste_uri must be undefined');
    ok(1) for 1..2;

    if ( $o->error eq 'Paste form was not found' ) {
        BAIL_OUT('Could not find paste form.'
            . ' It is very likely this module is broken.'
            . ' Please email to zoffix@cpan.org'
            . ' so this module could be fixed.');
    }
}
else {
    isa_ok($uri, 'URI::http');
    like( "$uri", qr|^http://pastebin\.ca/|, 'uri must be pointing to paste');
    isa_ok($o->paste_uri, 'URI::http');
    is( $uri, $o->paste_uri, '->uri and return from ->paste() must match');
}

