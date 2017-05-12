#!/usr/bin/perl

use lib qw( blib/arch );

use Test;
use WebMoney::WMSigner;

BEGIN { plan tests => 2 };

ok(1); # If we made it this far, we're ok.

my $wmid = '111111111111';
my $passwd = '111111111';
my $path = 'keys.kwm';
my $str = "And WHAT???\r\n";

$str = WebMoney::WMSigner::sign( $wmid, $passwd, $path, $str );

ok( $str, "Error 2\n" );
