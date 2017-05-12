use strict;
use warnings;

use FindBin qw($Bin);

use Test::More tests => 8;
use Test::Exception;

BEGIN {
    use_ok ('URI::tel');
}

our $uri_tel = new URI::tel;

ok (ref $uri_tel eq 'URI::tel');

dies_ok { $uri_tel->telephone_uri('aoijsdfs') }
    'Wrong tel uri';

lives_ok { $uri_tel->telephone_uri('tel:+1-201-555-0123') } 
    'New tel uri';

ok ($uri_tel->telephone_subscriber);

lives_ok { $uri_tel->telephone_uri('tel:7042;phone-context=ex.com') }
    'Nem tel uri with phone-context';

ok ( $uri_tel->context );

ok ( $uri_tel->tel_cmp('tel:123', 'tel:1(2)3') );

1;


