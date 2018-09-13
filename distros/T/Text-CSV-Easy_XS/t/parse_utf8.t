#!perl
use strict;
use warnings;
use utf8;

use Encode;
use Test::Deep;
use Test::More;
use Text::CSV::Easy_XS qw(csv_parse);

my ($str) = csv_parse(qq{"not utf-8"});
ok( !Encode::is_utf8($str), 'simple string is not utf-8' );

($str) = csv_parse(qq{"not ""utf-8"""});
ok( !Encode::is_utf8($str),
    'simple string with escape quote is not utf-8' );

($str) = csv_parse(qq{"✓"});
ok( Encode::is_utf8($str), encode_utf8('✓ is utf-8') );

($str) = csv_parse(qq{"""✓"""});
ok( Encode::is_utf8($str), encode_utf8('✓ with escape quote is utf-8') );

cmp_deeply( [ csv_parse(qq{"✓"}) ], ["✓"], 'UTF-8 support' );

done_testing();
