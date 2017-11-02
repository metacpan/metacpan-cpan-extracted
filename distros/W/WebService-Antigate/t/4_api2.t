#!/usr/bin/env perl

BEGIN {
	$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
	$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
	$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;
}

use strict;
use Test::More;
use WebService::Antigate;
use Net::HTTP;
use IO::Socket;
use JSON::PP;

use constant API_KEY      => 'd41d8cd98f00b204e9800998ecf8427e';
use constant CAPTCHA_ID   => 15;
use constant CAPTCHA_TEXT => 'txet_ahctpac';
use constant BALANCE      => 10;

if( $^O eq 'MSWin32' ) {
	plan skip_all => 'Windows still does not support fork()';
}

if (%IO::Socket::IP:: && IO::Socket::IP->VERSION < 0.35) {
	plan skip_all => 'Bugous IO::Socket::IP detected';
}

my ($pid, $host, $port) = make_api_server();
my $recognizer = WebService::Antigate->new(key => API_KEY, domain => "$host:$port", delay => 1, api_version => 2, scheme => "http", subdomain => '');

is($recognizer->upload(file => 't/captcha.jpg'), CAPTCHA_ID, '->upload(captcha.jpg)');
is($recognizer->last_captcha_id, CAPTCHA_ID, '->last_captcha_id');

is($recognizer->try_recognize(CAPTCHA_ID), undef, 'try_recognize() first attempt failed');
is($recognizer->errno, 'CAPCHA_NOT_READY', 'right errno set');

is($recognizer->try_recognize(CAPTCHA_ID), CAPTCHA_TEXT, 'try_recognize() second attempt success');
is($recognizer->errno, 'CAPCHA_NOT_READY', 'right errno set');

is($recognizer->recognize(CAPTCHA_ID), CAPTCHA_TEXT, '->recognize(CAPTCHA_ID)');
is($recognizer->recognize(CAPTCHA_ID+1), undef, '->recognize(CAPTCHA_ID+1)');

is($recognizer->abuse(CAPTCHA_ID), 'success', '->abuse(CAPTCHA_ID)');
is($recognizer->abuse(CAPTCHA_ID+1), undef, '->abuse(CAPTCHA_ID+1)');
is($recognizer->errno, 'ERROR_NO_SUCH_CAPCHA_ID', 'right errno set');
is($recognizer->errstr, 'Captcha you are requesting does not exist in your current captchas list or has been expired.', 'right errstr set');

is($recognizer->balance, BALANCE, '->balance()');
$recognizer->key('b026324c6904b2a9cb4b88d6d61c81d1');
is($recognizer->balance, undef, '->balance() & bad key');
is($recognizer->errno, 'ERROR_KEY_DOES_NOT_EXIST', 'right errno set');

kill 15, $pid;

done_testing();

my $serv_i = 0;
sub make_api_server {
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
	
	my $child = fork;
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $headers;
			my $body;
			while (1) {
				$client->sysread($headers, 1024, length $headers)
					or last;
				if (( my $offset = rindex($headers, "\015\012\015\012") ) != -1) {
					$body = substr($headers, $offset + 4);
					substr($headers, $offset + 4) = '';
					last;
				}
			}
			
			my ($len) = $headers =~ /Content-Length:\s+(\d+)/;
			while (length $body < $len) {
				$client->sysread($body, 1024, length $body);
			}
			
			my $response = { errorId => 0 };
			my $req = decode_json($body);
			unless ($req->{clientKey} eq API_KEY) {
				$response->{errorId} = 1;
				$response->{errorCode} = 'ERROR_KEY_DOES_NOT_EXIST';
				$response->{errorDescription} = 'Account authorization key not found in the system';
				goto RESP;
			}
			
			if ($headers =~ m!^POST.+/createTask!) {
				if ( exists $req->{task} && exists $req->{task}{type} ) {
					$response->{taskId} = CAPTCHA_ID;
				}
				else {
					$response->{errorId} = 22;
					$response->{errorCode} = 'ERROR_TASK_ABSENT';
					$response->{errorDescription} = 'Task property is empty or not set in createTask method. Please refer to API v2 documentation.';
				}
			}
			elsif ($headers =~ m!^POST.+/getBalance!) {
				$response->{balance} = BALANCE;
			}
			elsif ($headers =~ m!^POST.+/getTaskResult!) {
				if ( $req->{taskId} == CAPTCHA_ID ) {
					$response->{status} = $serv_i % 2 == 0 ? 'processing ' : do {
						$response->{solution} = { text => CAPTCHA_TEXT };
						'ready';
					};
				}
				else {
					$response->{errorId} = 16;
					$response->{errorCode} = 'ERROR_NO_SUCH_CAPCHA_ID';
					$response->{errorDescription} = 'Captcha you are requesting does not exist in your current captchas list or has been expired.';
				}
				
				$serv_i++;
			}
			elsif ($headers =~ m!^POST.+/reportIncorrectImageCaptcha!) {
				if ( $req->{taskId} == CAPTCHA_ID ) {
					$response->{status} = 'success';
				}
				else {
					$response->{errorId} = 16;
					$response->{errorCode} = 'ERROR_NO_SUCH_CAPCHA_ID';
					$response->{errorDescription} = 'Captcha you are requesting does not exist in your current captchas list or has been expired.';
				}
			}
			
			RESP:
			$client->syswrite(
				join(
					"\015\012",
					"HTTP/1.1 200 OK",
					"Connection: close",
					"Content-Type: text/html",
					"\015\012"
				) . encode_json($response)
			);
			$client->close();
		}
		
		exit;
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}

