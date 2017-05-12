use Test::More tests => 8;
use Test::Exception;

use VM::JiffyBox; # we have checked this already in 00_load.t

my $module = 'VM::JiffyBox';

can_ok($module, 'new'); 

dies_ok { $module->new(); } 'Die if no token';

my $token = 'MyToken';
my $jiffy = $module->new(token => $token);
isa_ok($jiffy, $module);

is($jiffy->token, $token, 'Check Token');

can_ok($jiffy, 'get_vm'); 

dies_ok{$jiffy->get_vm();} 'Die if no ID';

my $box_id = 'MyBoxID';
my $box = $jiffy->get_vm($box_id);

is($box->id, $box_id, 'Check ID');
is($box->{hypervisor}->token, $token, 'Check Token @ Box');

