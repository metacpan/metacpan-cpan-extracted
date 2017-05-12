use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use Test::More tests => 6;
use Test::Exception;

use UR;

use_ok('Command::SubCommandFactory') or die;
use_ok('CmdTest::Thing::Create') or die;

my @sub_command_classes;
lives_ok(sub{ @sub_command_classes = CmdTest::Thing::Create->sub_command_classes; }, 'sub_command_classes');
is_deeply(\@sub_command_classes, ['CmdTest::Thing::Create::One'], 'sub_command_classes are correct');
lives_ok(sub{ CmdTest::Thing::Create::One->__meta__; }, 'create thing one command meta');
throws_ok(sub{ CmdTest::Thing::Create::Two->__meta__; }, qr/Can't locate object method "__meta__"/, 'no thing two create command meta');

done_testing();
