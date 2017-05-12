use strict;
use warnings;
use Test::More tests => 11;

use YAML::Syck;

ok( YAML::Syck->VERSION );
is( Dump("Hello, world"),       "--- Hello, world\n" );
is( Load("--- Hello, world\n"), "Hello, world" );

TODO: {
    local $TODO = 'RT 34073 - Parsing YAML without separator';
    my $out = eval { Load("--\n") };
    isnt( $@, '', "Bad data dies on Load" );
    is( $out, undef, "Bad data fails load" );
}

TODO: {
    my $out = eval { Load("") };
    is( $out, undef, "Bad data fails load" );

    local $TODO = 'Load fails on empty string';
    isnt( $@, '', "Bad data dies on Load" );
}

TODO: {
    my $out = eval { Load("feefifofum\n\n\ndkjdkdk") };

    local $TODO = 'Load fails on empty string';
    isnt( $@, '', "Bad data dies on Load" );
    is( $out, undef, "Bad data fails load" );
}

TODO: {
    my $out = eval { Load("---\n- ! >-\n") };

    local $TODO = 'RT 23850 - META.yml of DMAKI/DateTime-Format-Japanese-0.01.tar.gz cannot be parsed';
    is( $@, '', "Bad data dies on Load" );
    is_deeply( $out, [''], "Bad data fails load" );
}
