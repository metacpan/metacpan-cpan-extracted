use Test::More 'no_plan';

use_ok('perfSONAR_PS::Status::Link');
use perfSONAR_PS::Status::Link;

my $link_id = "link1";
my $knowledge = "full";
my $start_time = 1000;
my $end_time = 1010;
my $oper_status = "up";
my $admin_status = "normaloperation";

my $link1 = perfSONAR_PS::Status::Link->new($link_id, $knowledge, $start_time, $end_time, $oper_status, $admin_status);
ok (defined $link1);
is ($link1->getID, $link_id);
is ($link1->getKnowledge, $knowledge);
is ($link1->getStartTime, $start_time);
is ($link1->getEndTime, $end_time);
is ($link1->getOperStatus, $oper_status);
is ($link1->getAdminStatus, $admin_status);

$link1 = perfSONAR_PS::Status::Link->new();
ok (defined $link1);

ok (!defined $link1->getID);
ok (!defined $link1->getKnowledge);
ok (!defined $link1->getStartTime);
ok (!defined $link1->getEndTime);
ok (!defined $link1->getOperStatus);
ok (!defined $link1->getAdminStatus);

$link1->setID($link_id);
is ($link1->getID, $link_id);
$link1->setKnowledge($knowledge);
is ($link1->getKnowledge, $knowledge);
$link1->setStartTime($start_time);
is ($link1->getStartTime, $start_time);
$link1->setEndTime($end_time);
is ($link1->getEndTime, $end_time);
$link1->setOperStatus($oper_status);
is ($link1->getOperStatus, $oper_status);
$link1->setAdminStatus($admin_status);
is ($link1->getAdminStatus, $admin_status);
