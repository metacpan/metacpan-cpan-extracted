#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Try::Tiny;
use Test::More tests => 21;

use FindBin qw($Bin);
use lib "$Bin/../lib";

my %data = (
  api_user => 'jlloyd',
  api_key => 'abcdefg123456789',
  test_mode => 1,
  to => 'jlloyd@cpan.org',
  from => 'jlloyd@cpan.org',
  subject => 'This is a test',
  text => 'This is a test message',
  html => '<html><head></head><body>This is a test HTML message</body></html>'
);

use_ok( 'WebService::SendGrid::Mail' );
require_ok( 'WebService::SendGrid::Mail' );

my $mail = WebService::SendGrid::Mail->new(%data);
isa_ok($mail, 'WebService::SendGrid::Mail');
can_ok($mail, qw(send));

my $res = $mail->send;
is (ref $res, 'HASH', 'Valid return type');
ok (defined $res->{message}, 'Valid return data');
ok ($res->{message} eq 'success', 'Successful response');

try {
	my $mail = WebService::SendGrid::Mail->new;
}
catch {
	my $regex = qr/Attribute \((api_key|api_user|to|from|subject|date)\) is required/;
	like ($_, $regex, 'Requirements test');
};

for my $attr (qw(to from bcc replyto)) {
	try {
		my %data = %data;
		$data{$attr} = 'Bad email';
		my $mail = WebService::SendGrid::Mail->new(%data);
	}
	catch {
		my $regex = qr/Attribute \($attr\) does not pass the type constraint/;
		like ($_, $regex, 'Email format test');
	};
}

my @array_of_email_arrays;
push @array_of_email_arrays, ['good_email@example.com', 'fine_email@examples.com'];
push @array_of_email_arrays, ['good_email@example.com', 'Bad email'];
push @array_of_email_arrays, ['Bad email', 'good_email@example.com'];
push @array_of_email_arrays, ['Bad email', 'Bad Email'];

for my $attr (qw(to bcc)) {
	for my $test (@array_of_email_arrays) {
		try {
			my %data = %data;
			$data{$attr} = $test;
			my $mail = WebService::SendGrid::Mail->new(%data);
		}
		catch {
			my $regex = qr/Attribute \($attr\) does not pass the type constraint/;
			like ($_, $regex, 'Multiple Email format test');
		};
	}
}

for my $attr (qw(html text)) {
	try {
		my %data = %data;
		delete $data{$attr};
		my $mail = WebService::SendGrid::Mail->new(%data);
	}
	catch {
		fail('Either/or Content test');
	}
	finally {
		pass('Either/or Content test');
	};
}

try {
	my %data = %data;
	delete $data{$_} for qw(text html);
	my $mail = WebService::SendGrid::Mail->new(%data);
	$mail->send;
}
catch {
	my $regex = qr/No content/;
	like ($_, $regex, 'And Content Test');
};
