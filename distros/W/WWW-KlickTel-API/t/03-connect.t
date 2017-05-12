#!perl -T

# $Id: 03-connect.t 32 2013-03-14 14:32:24Z sysdef $

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    ok(
        eval {
            use WWW::KlickTel::API;
            my $klicktel = WWW::KlickTel::API->new( api_key => '000', );
            my $result_hash_ref = $klicktel->invers('000');

            if ( ref $result_hash_ref->{'response'}{'error'} eq 'HASH' ) {
                my $message =
                    $result_hash_ref->{'response'}{'error'}{'message'};
                my $test_text =
                    'die Sie beim Erstellen des Keys angegeben haben,'
                        . ' vorgenommen werden.';

                return 1 if $message =~ /$test_text\z/;
                return 0;
            }
        },
        "connect to klicktel.de API"
    );

}
