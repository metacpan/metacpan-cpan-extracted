#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::MockObject;
use Hash::AsObject;
use Test::Exception;

use POE;

use ok "Verby::Action::Run";
use ok "Verby::Action::Run::Unconditional";

{
	package MyAction;
	use Moose;

	with "Verby::Action::Run::Unconditional";

	sub do {
		my ( $self, $c, @args ) = @_;
		$self->create_poe_session( c => $c, @args );
	}
}

isa_ok(my $a = MyAction->new, "MyAction");

my $logger = Test::MockObject->new;
$logger->set_true($_) for qw/info warning debug/;
$logger->mock("log_and_die" => sub { shift; die "@_" });

can_ok($a, "create_poe_session");

my $e; # $@ but doesn't get smashed by Test::More & friends


sub run_poe (&) {
	my $code = shift;

	eval {
		POE::Session->create(
			inline_states => {
				_start => sub { $_[KERNEL]->yield("start_code") },
				_stop  => sub { },
				_child => sub { },
				start_code => sub { $code->(); return },
			},
		);

		$poe_kernel->run;
	};

	$e = $@;
}

SKIP: {
	my $true = "/usr/bin/true";
	skip "no true(1)", 3 unless -x $true;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	ok( !$a->verify($c), "command not yet verified" );
	run_poe { $a->do( $c, cli => [$true]) };
	ok( !$e, "exec of true" ) || diag $e;
	ok( $a->verify($c), "command verified" );
}

SKIP: {
	my $false = "/usr/bin/false";
	skip "no false(1)", 2 unless -x $false;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	ok( !$a->verify($c), "command not yet verified" );
	run_poe { $a->do( $c, cli => [$false]) };
	ok( $e, "exec of 'false'" ) || diag "no exception for false";
	ok( $a->verify($c), "command verified" );
}

SKIP: {
	my $wc = "/usr/bin/wc";
	skip "no wc(1)", 6 unless -x $wc;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	my $in = <<FOO;
line 1
foo
bar
FOO

	ok( !$a->verify($c), "command not yet verified" );
	run_poe { $a->do( $c, cli => [$wc, "-l"], in => \$in ) };
	ok( !$e, "wc -l didn't die" ) || diag($e);
	ok( $a->verify($c), "command verified" );
	my ($out, $err) = ( $c->stdout, $c->stderr );
	like($out, qr/^\s*\d+\s*$/, "output of wc -l looks sane");
	is( ($err || ""), "", "no stderr");
	ok(!$logger->called("warning"), "no warnings logged");
}

SKIP: {
	my $sh = "/bin/sh";
	skip "no sh(1)", 5 unless -x $sh;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	my $str = "foo";

	ok( !$a->verify($c), "command not yet verified" );
	run_poe { $a->do( $c, cli => [$sh,  "-c", "echo $str 1>&2"]) };
	ok( $a->verify($c), "command verified" );
	
	my ($out, $err) = ( $c->stdout, $c->stderr );
	chomp($err);
	is($err, $str, "stderr looks good");

	$logger->called_ok("warning");
}

SKIP: {
	my $true = "/usr/bin/true";
	skip "no true(1)", 2 unless -x $true;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	my $e = "blah\n";
	my $o = "gorch\n";
	my $init = sub { warn $e; print STDOUT $o };

	run_poe { $a->do( $c, cli => [$true], init => $init ) };
	my ($out, $err) = ( $c->stdout, $c->stderr );

	$_ ||= '', chomp for $out, $err, $e, $o;

	is($out, $o, "init invoked and outputted to stdout");
	is($err, $e, "... and stderr");
}

