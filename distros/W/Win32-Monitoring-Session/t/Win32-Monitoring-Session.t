# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Monitoring-Session.t'

use lib qw(blib/arch blib/lib);
use Test::More tests => 4;
BEGIN {use_ok('Win32::Monitoring::Session', qw(:all))};
my $s;
my $i;
ok($s = GetLogonSessionId($$)   ,'Get LogonSessionId for current process: $$ -> '.($s || '?'));
ok($i = GetLogonSessionData($s) ,'Get LogonSessionData: '.($i || '?'));
ok($i->{LogonTime}              ,'Check for LogonTime: '.(localtime $i->{LogonTime}||'???'));

