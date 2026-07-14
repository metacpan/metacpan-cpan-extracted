#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('WWW::Mechanize');
    use_ok('JSON::PP');
    use_ok('Digest::SHA');
    use_ok( 'WWW::Pastebin::PastebinCa::Create' );
}

diag( "Testing WWW::Pastebin::PastebinCa::Create $WWW::Pastebin::PastebinCa::Create::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::PastebinCa::Create->new;

isa_ok( $o, 'WWW::Pastebin::PastebinCa::Create');
can_ok( $o, qw(new paste_uri error mech paste valid_langs valid_expires
                    _set_error));

isa_ok( $o->mech, 'WWW::Mechanize');

done_testing();
