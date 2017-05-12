#!/usr/bin/perl
###########################################################

use Test ;
use Text::Scan ;

BEGIN{ plan tests => 1 + 1 + 1 + 1 + 1 + 1 + 1 }

my $dict = new Text::Scan;

ok($dict);

my $inclboundary =
    "\x{e0}\x{e1}\x{e2}\x{e3}\x{e4}\x{e5}\x{e6}\x{e7}\x{e8}\x{e9}\x{ea}\x{eb}\x{ec}\x{ed}\x{ee}\x{ef}" ;

# the sentence "I can eat glass and it doesn't hurt my body" in chinese (utf8 binary)
my $text = "\x{e6}\x{88}\x{91}\x{e8}\x{83}\x{bd}\x{e5}\x{90}\x{9e}\x{e4}\x{b8}\x{8b}\x{e7}\x{8e}\x{bb}\x{e7}\x{92}\x{83}\x{e8}\x{80}\x{8c}\x{e4}\x{b8}\x{8d}\x{e4}\x{bc}\x{a4}\x{e8}\x{ba}\x{ab}\x{e4}\x{bd}\x{93}\x{e3}\x{80}\x{82}";

my $first = "\x{e6}\x{88}\x{91}" ;
my $glass = "\x{e7}\x{8e}\x{bb}\x{e7}\x{92}\x{83}";
my $body  = "\x{e8}\x{ba}\x{ab}\x{e4}\x{bd}\x{93}";
my $last  = "\x{e3}\x{80}\x{82}" ;

$dict->inclboundary($inclboundary) ;

ok($dict) ;

$dict->insert($glass, 'glass');
$dict->insert($body, 'body' );
$dict->insert($first,'first');
$dict->insert($last, 'last');

ok($dict) ;

my @answers = $dict->scan($text) ;

ok ( scalar( grep { $_ eq 'body' }  @answers ) );
ok ( scalar( grep { $_ eq 'glass' } @answers ) );
ok ( scalar( grep { $_ eq 'first' } @answers ) );
ok ( scalar( grep { $_ eq 'last' }  @answers ) );
