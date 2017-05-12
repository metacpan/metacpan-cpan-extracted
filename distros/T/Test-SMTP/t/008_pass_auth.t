# -*- perl -*-

use strict;
use warnings;

use lib 't';

use IO::Socket;
use Net::Server::Mail::ESMTP;
use Test::SMTP;
use Test::More;
use Sys::Hostname;

plan tests => 6;

my $LOCAL_PORT = $ENV{'SMTP_SERVER_PORT'} || 2525;

#spawn off a server

SKIP: {
    skip "Stub server doesn't support AUTH", 6;

my $server_pid;

    my $server;
    while(not defined $server && $LOCAL_PORT < 4000)
    {
        $server = new IO::Socket::INET(
            Listen => 1,
            LocalPort => ++$LOCAL_PORT
	);
    } 

$server_pid = fork();

if ($server_pid == 0){
    # I'm the child process
    my $conn_number = 0;
    my $conn;
    while ($conn = $server->accept)
    {
        my $issue_an_error_on_quit = 0;
	my $issue_an_error_on_rset = 0;

        my $esmtp = Net::Server::Mail::ESMTP->new(socket => $conn);
        # activate some extensions
	$esmtp->register('Net::Server::Mail::ESMTP::AUTH');
	# adding some handlers
	$esmtp->set_callback(AUTH => sub {
            my ($session, $username, $password) = @_;
	    if ($password eq 'goodpassword'){
	        return 1;
            } else {
                return 0;
	    }
	});
	$esmtp->process();
        $conn->close();
	$conn_number++;
        if ($conn_number == 2) {
	   $server->close;
	   exit 1;
	};
    }
}

diag("Spawned server pid: $server_pid");
diag("Starting tests");
sleep 1; 

my $c1 = Test::SMTP->connect_ok("connects to SMTP on $LOCAL_PORT",
                                Host => '127.0.0.1', 
#                                Port => 25,
				Port => $LOCAL_PORT, 
				Hello => 'example.com',
				AutoHello => 1,
				Debug => 1,
				) or die "Can't connect to the SMTP server so can't go on testing";

$c1->supports_like('AUTH', qr/PLAIN/, 'Supports PLAIN auth');
$c1->auth_ko('PLAIN',   'user', 'badpassword',  'Passes because auth is rejected');
$c1->auth_ok('PLAIN',   'user', 'goodpassword', 'Passes because auth is accepted');
#$c1->auth_ko('user', 'badpassword',  'Passes because auth is rejected');
#$c1->auth_ok('user', 'goodpassword', 'Passes because auth is accepted');

$c1->quit_ok('Passes because the server quits');

my $c2 = Test::SMTP->connect_ok("connects to SMTP on $LOCAL_PORT",
                                Host => '127.0.0.1',
#                                Port => 25,
                                Port => $LOCAL_PORT,
                                Hello => 'example.com',
                                AutoHello => 1,
				Debug => 1,
                                ) or die "Can't connect to the SMTP server so can't go on testing";


$c1->supports_like('AUTH', qr/LOGIN/, 'Supports LOGIN auth');
$c2->auth_ok('LOGIN',   'user', 'goodpassword', 'Passes because auth is accepted');
#$c2->auth_ok('user', 'goodpassword', 'Passes because auth is accepted');

$c2->quit_ok('Passes because the server quits');

kill 1, $server_pid;
wait;

}
