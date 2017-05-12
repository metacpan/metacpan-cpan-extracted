#basic check with valid files

use strict;
use warnings;
use XML::Jing;
use Test::More;
use Path::Tiny;
use FindBin qw($Bin);

plan tests => 3;
my $jing;
ok($jing = XML::Jing->new(path($Bin, 'data','test.rng')), 'successfully reads a valid RNG');
my $error = $jing->validate(path($Bin, 'data','testPASS.xml'));
ok(! $error, 'returns nothing when XML file is valid')
	or note $error;

$error = $jing->validate(path($Bin,'data','testFAIL.xml'));
is($error, 'element "ballBoy" not allowed anywhere; expected the element end-tag or element "player"');