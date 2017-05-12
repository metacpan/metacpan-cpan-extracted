use Test::More 'no_plan';
use Data::Compare qw( Compare );

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

use_ok('perfSONAR_PS::Transport');
use perfSONAR_PS::Transport;

my $transport = perfSONAR_PS::Transport->new("localhost", 8080, "/test");
ok (defined $transport);
ok ($transport->{CONTACT_HOST} eq "localhost");
ok ($transport->{CONTACT_PORT} == 8080);
ok ($transport->{CONTACT_ENDPOINT} eq "/test");
$transport->setContactHost("localhost2");
ok ($transport->{CONTACT_HOST} eq "localhost2");
$transport->setContactPort(12345);
ok ($transport->{CONTACT_PORT} == 12345);
$transport->setContactEndPoint("/test2");
ok ($transport->{CONTACT_ENDPOINT} eq "/test2");
my $uri = "http://localhost:8080/test";
my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($uri);
ok ($host eq "localhost");
ok ($port == 8080);
ok ($endpoint eq "/test");
ok ($uri eq &perfSONAR_PS::Transport::getHttpURI("localhost", 8080, "test"));
ok ($uri eq &perfSONAR_PS::Transport::getHttpURI("localhost", 8080, "/test"));
my $error;
my $n = $transport->sendReceive("", "", \$error);
ok ($error ne "");

print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

