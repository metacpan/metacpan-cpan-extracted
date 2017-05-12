# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WoW-Wikki.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('WoW::Wiki') };
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = WoW::Wiki->new();
isa_ok( $parser, "WoW::Wiki" );

my $data = $parser->parse('UIHANDLER_OnClick');
ok( (defined($data) ), "Data was valid" );

isa_ok($data, 'ARRAY');

my $edata = $parser->parse('Events/Combat');
isa_ok($edata, 'ARRAY');

foreach(@{$edata})
{
	print STDERR Dumper($_) . "\n";
}
