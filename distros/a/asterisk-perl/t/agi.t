use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 5}

my $module_name = 'Asterisk::AGI';
use_ok( $module_name) or exit;
#use Asterisk::AGI;

my $object = new $module_name;
isa_ok( $object, $module_name);

my @methods=qw( answer channel_status control_stream_file database_deltree
database_get database_put exec  get_data get_full_variable get_variable
noop receive_char receive_text record_file say_alpha say_datetime_all say_time
say_datetime say_digits say_number say_phonetic send_image send_text
set_autohangup set_callerid set_context set_extension set_music set_priority
set_variable stream_file tdd_mode verbose wait_for_digit);

can_ok( $module_name, @methods );

my $fh;
open($fh, "<t/agi.head") || die;
my %vars = $object->ReadParse($fh);
close($fh);
ok(%vars);
open($fh, "<t/agi.goodresponse") || die;
my $response = $object->_readresponse($fh);
ok($response);
