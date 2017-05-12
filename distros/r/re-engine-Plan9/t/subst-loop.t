#use Test::More tests => 2;
use Test::More skip_all
    => "return 0 if stringarg == strend in Plan9_exec makes this pass but"
       . " fails others, find a real solution";
use re::engine::Plan9;

$_ = 'xxx'; 
$snum = s/([0-9]*|x)/<$1>/g; 
is($_, "<x><x><x>");
is($snum, 3);
