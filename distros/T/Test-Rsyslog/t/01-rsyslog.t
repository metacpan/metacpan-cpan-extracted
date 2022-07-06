#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Rsyslog();
use Sys::Syslog();

plan tests => 13;

{
	local %ENV = %ENV;
	local $ENV{'PATH'} = '/usr/bin:/usr/sbin:/sbin:/bin';
	delete $ENV{'BASH_ENV'};
	delete $ENV{'ENV'};
	delete $ENV{'IFS'};
	delete $ENV{'CDPATH'};
	diag(`rsyslogd -v`);
}
my $rsyslog = Test::Rsyslog->new();
ok($rsyslog, "Created Test Rsyslog object");

if ($Sys::Syslog::VERSION ge 0.28) {
	diag("Sys::Syslog VERSION is $Sys::Syslog::VERSION, using new interface");
	Sys::Syslog::setlogsock({ type => 'unix', path => $rsyslog->socket_path() });
} else {
	diag("Sys::Syslog VERSION is $Sys::Syslog::VERSION, using old interface");
	Sys::Syslog::setlogsock('unix', $rsyslog->socket_path());
}
Sys::Syslog::openlog($0 . '[' . $$ . ']','cons','LOG_LOCAL7');
my $plain = 'This is a test message';
my @messages = $rsyslog->messages();
ok(Sys::Syslog::syslog('info|LOG_LOCAL7', $plain), "Sent '$plain' to rsyslog");
Sys::Syslog::closelog();
while(($rsyslog->alive()) && (@messages == $rsyslog->messages())) {
	diag("Waiting for rsyslog to output log message");
	sleep 1;
}
$rsyslog->stop();
ok(!$rsyslog->alive(), "Rsyslogd has been stopped");
@messages = $rsyslog->find($plain);
ok(scalar @messages == 1, "Found 1 matching log message");
my $quoted = quotemeta $plain;
ok($messages[0] =~ /$quoted/smx, q[Found '] . (join q[, ], @messages) . q[']);
foreach my $line ($rsyslog->messages()) {
	diag(Encode::encode('UTF-8', $line, 1));
}
$rsyslog->scrub();
$rsyslog->start();
Sys::Syslog::openlog($0 . '[' . $$ . ']','cons','LOG_LOCAL0');
@messages = $rsyslog->messages();
my $unicode = 'This is a ' . (chr 1606) . ' unicode ' . (chr 29399) . ' message';
my $copy = $unicode;
my $encoded = Encode::encode('UTF-8', $copy, 1);
ok(Sys::Syslog::syslog('LOG_INFO|LOG_LOCAL0', $encoded), "Sent '$encoded' to rsyslog");
Sys::Syslog::closelog();
while(($rsyslog->alive()) && (@messages == $rsyslog->messages())) {
	diag("Waiting for rsyslog to output log message");
	sleep 1;
}
$rsyslog->stop();
ok(!$rsyslog->alive(), "Rsyslogd has been stopped");
@messages = $rsyslog->find($unicode);
ok(scalar @messages == 1, "Found 1 matching log message");
$quoted = quotemeta $unicode;
ok($messages[0] =~ /$quoted/smx, q[Found '] . (join q[, ], map { Encode::encode('UTF-8', $_, 1) } @messages) . q[']);
foreach my $line ($rsyslog->messages()) {
	diag(Encode::encode('UTF-8', $line, 1));
}
$rsyslog->scrub();
$rsyslog->start();
Sys::Syslog::openlog($0 . '[' . $$ . ']','cons','LOG_USER');
my $special = "This is a \x05message\r\n with special @\b characters" . (join q[ ], map { chr $_ } 0 .. 40);
@messages = $rsyslog->messages();
ok(Sys::Syslog::syslog('LOG_INFO|LOG_USER',$special), 'Sent a message containing every known special character to rsyslog');
Sys::Syslog::closelog();
while(($rsyslog->alive()) && (@messages == $rsyslog->messages())) {
	diag("Waiting for rsyslog to output log message");
	sleep 1;
}
$rsyslog->stop();
ok(!$rsyslog->alive(), "Rsyslogd has been stopped");
@messages = $rsyslog->find($special);
ok(scalar @messages == 1, "Found 1 matching log message");
ok($messages[0] =~ /special/smx, q[Found '] . (join q[, ], @messages) . q[']);
foreach my $line ($rsyslog->messages()) {
	diag(Encode::encode('UTF-8', $line, 1));
}
