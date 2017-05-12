
use strict;
use warnings;

use Test::More tests => 2+2+5+4+4;
use lib '.';
require t::make_ini;

&test01_get;    # 2
&test02_fault;  # 2
&test03_post1;  # 5
&test04_post2;  # 4
&test05_upload; # 4

sub test01_get
{
	# GET is not affected by TL/maxrequestsize.
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				maxrequestsize => 1,
			},
		},
		method => 'GET',
		param  => { test => 'value' },
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print("ok");
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 1);
		is($ret->{content}, 'ok', "[test1] GET is not affected by TL/maxrequestsize" );
	}
}

sub test02_fault
{
	# no fault handler (default).
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				maxrequestsize => 1,
			},
		},
		method => 'POST',
		param  => { test => 'value' },
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print("not reach here");
			});
		},
	});
	SKIP:{
		ok(!$ret->is_success, "[test2] fetch failed");
		like($ret->{content}, qr/Post Error: request size was too big to accept./, "[test2] request too big");
	}
}

sub test03_post1
{
	# fault handler.
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				maxrequestsize => 1,
				fault_handler => '_test3_fault_handler',
			},
		},
		method => 'POST',
		param  => { test => 'value' },
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print("not reach here");
			});
		},
	});
	SKIP:{
		ok(!$ret->is_success, "[test3] fetch failed");
		is_deeply($ret->{headers}{Status}, ["413 Request Entity Too Large"], "[test3] Status: 413 Request Entity Too Large");
		like($ret->{content}, qr/Post Error: request size was too big to accept./, "[test3] request too big");
		like($ret->{content}, qr/^test3 handler\n/, "[test3] customized content");
		unlike($ret->{content}, qr/<html\b/, "[test3] customized content, no html tag");
	}
}
sub _test3_fault_handler
{
	my $pkg = shift;
	my $err = shift;
	my $status = ref($err) && $err->{http_status_line};
	$status ||= '599 Internal Server Error';
	print "Status: $status\r\n";
	print "Content-Type: text/plain\r\n";
	print "\r\n";
	my $ref = ref($err) || '-';
	print "test3 handler\n";
	print "error = (#$ref)\n$err\n";
}

sub test04_post2
{
	# fault handler in another module.
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				maxrequestsize => 1,
				fault_handler  => 't::FaultHandler::my_fault_handler',
			},
		},
		method => 'POST',
		param  => { test => 'value' },
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print("not reach here");
			});
		},
	});
	SKIP:{
		ok(!$ret->is_success, "[test4] fetch failed");
		like($ret->{content}, qr/Post Error: request size was too big to accept./, "[test4] request too big");
		like($ret->{content}, qr/^pkg = t::FaultHandler\b/, "[test4] customized content(2)");
		unlike($ret->{content}, qr/<html\b/, "[test4] customized content(2), no html tag");
	}
}

sub test05_upload
{
	# fault handler.
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				#maxrequestsize => 1,
				maxfilesize => 1,
				fault_handler => '::_test5_fault_handler',
				#logdir => 'logs',
			},
			Debug => {
				enable_debug    => 1,
				request_logging => 1,
				content_logging => 1,
			},
		},
		method => 'POST',
		param  => { test => 'value' },
		file   => {
			file => 'data',
		},
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print("not reach here");
			});
		},
	});
	SKIP:{
		ok(!$ret->is_success, "[test5] fetch failed")
			or diag($ret->{content}),skip('fetch succeeded unexpectedly', 3);
		like($ret->{content}, qr/we are getting too large file which exceeds the limit./, "[test5] file too big");
		like($ret->{content}, qr/^test5 handler\n/, "[test5] customized content");
		unlike($ret->{content}, qr/<html\b/, "[test5] customized content, no html tag");
	}
}
sub _test5_fault_handler
{
	my $pkg = shift;
	my $err = shift;
	print "Status: 500 Error\r\n";
	print "Content-Type: text/plain\r\n";
	print "\r\n";
	my $ref = ref($err) || '-';
	print "test5 handler\n";
	print "error = (#$ref)\n$err\n";
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
