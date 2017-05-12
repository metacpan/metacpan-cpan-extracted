#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::MockObject;
use Test::Exception;

use ok 'Template';

use File::Temp qw/tempfile/;
use File::Spec;
use Verby::Config::Data;

my $m; BEGIN { use_ok($m = "Verby::Action::Template") };

my $template = <<TMPL;
foo bar gorch
foo='[% c.foo() %]'
ding ding ding
TMPL

my $c = Verby::Config::Data->new;
%{ $c->data } = (
	template => \$template,
	logger => Test::MockObject->new,
	foo => "blah",
);

$c->logger->set_true($_) for qw/info/;
$c->logger->mock(logdie => sub { shift; die "@_" });

isa_ok(my $a = $m->new, $m);

{
	(my $outfh, $c->data->{output}) = tempfile(UNLINK => 1);

	can_ok($a, "do");

	lives_ok { $a->do($c) } "template had no errors";

	ok($a->verify($c), "verififcation successful");

	my $output = do { local $/; <$outfh> };
	like($output, qr/foo='blah'/s, "output looks good");
}

{
	my ($outfh, $outfile) = tempfile(UNLINK => 1);
	$c->data->{output} = $outfile;
	chmod 0, $outfile or die "couldn't chmod '$outfile': $!";

	$c->logger->clear;
	dies_ok { $a->do($c) } "action dies when output not writable";
	$c->logger->called_ok("logdie");
}
