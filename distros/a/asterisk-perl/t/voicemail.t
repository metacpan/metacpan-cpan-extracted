#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 11}

my $module_name = 'Asterisk::Voicemail';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw( spooldirectory sounddirectory serveremail format vmbox getfolders
configfile readconfig appendsoundfile validmailbox msgcount msgcountstr
createdefaultmailbox messages);

can_ok( $module_name, @methods);

ok( $object->configfile() eq '/etc/asterisk/voicemail.conf', "Default vm conf file");

$object->configfile('/tmp/etc/asterisk/voicemail.conf');

ok( $object->configfile() eq '/tmp/etc/asterisk/voicemail.conf', "Custom vm conf file");

ok( $object->spooldirectory eq '/var/spool/asterisk/vm' , "Default vm spool directory"); 

$object->spooldirectory('/tmp/var/spool/asterisk/vm');

ok( $object->spooldirectory eq '/tmp/var/spool/asterisk/vm', "Custom vm spool directory" );

ok( $object->sounddirectory eq '/var/lib/asterisk/sounds' , "Default vm sound directory"); 

$object->sounddirectory('/tmp//var/lib/asterisk/sounds');

ok( $object->sounddirectory eq '/tmp//var/lib/asterisk/sounds', "Custom vm sound directory" );

ok( ! $object->serveremail() , "Default serveremail value");

$object->serveremail("test\@email.com");

ok( $object->serveremail eq "test\@email.com", "Custom serveremail value");

