use Test::More 'no_plan';

use_ok('perfSONAR_PS::Client::Echo');
use perfSONAR_PS::Client::Echo;

my $uri1 = "http://localhost:8080/test";
my $defEventType = "http://schemas.perfsonar.net/tools/admin/echo/2.0";
my $client1 = perfSONAR_PS::Client::Echo->new($uri1);

ok (defined $client1);
ok ($client1->{URI} eq $uri1);
ok ($client1->{EVENT_TYPE} eq $defEventType);

my $eventType = "echo.ma";
my $client2 = perfSONAR_PS::Client::Echo->new($uri1, $eventType);
ok ($client2->{EVENT_TYPE} eq $eventType);

my $uri2 = "http://localhost2:8083/ping/test";
$client2->setURIString($uri2);
ok ($client2->{URI} eq $uri2);

$client2->setEventType($defEventType);
ok ($client2->{EVENT_TYPE} eq $defEventType);

my ($n, $error) = $client2->ping();
ok ($n == -1);
ok ($error ne "");
