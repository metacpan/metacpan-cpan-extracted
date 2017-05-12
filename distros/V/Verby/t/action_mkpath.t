#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::MockObject;
use Test::Exception;

use File::Temp qw/tempdir/;
use File::Path qw/rmtree/;
use File::Spec;

my $m; BEGIN { use_ok($m = "Verby::Action::MkPath") }

my $dir = tempdir(CLEANUP => 1);

my $c = Test::MockObject->new;
$c->set_false("error");
$c->set_always(path => my $target = File::Spec->catdir($dir, qw/some nested dir/));
$c->set_always(logger => my $logger = Test::MockObject->new);

$logger->set_true("info");
$logger->mock(log_and_die => sub { shift; die "@_" });

isa_ok(my $a = $m->new, $m);

ok(! -e $target, "dir '$target' does not yet exist");

ok(!$a->verify($c), "verify is false");

$c->called_ok("path");

dies_ok { $a->confirm($c) } "confirm is fatal";

$c->clear;

lives_ok { $a->do($c) } "do doesn't die";

$c->called_ok("path");

ok($a->verify($c), "verify is true");
lives_ok { $a->confirm($c) } "confirm lives";

ok(-d $target, "target exists now");

dies_ok { $a->do($c) } "can't create twice, directory exists";

my $target_f = File::Spec->catfile($target, "foo");
open my $fh, ">", $target_f;

$c->set_always(path => $target_f);

isa_ok(my $b = $m->new, $m);
ok(!$b->verify($c), "file isn't a dir");

dies_ok { $b->do($c) } "can't do";

dies_ok { $b->confirm($c) } "can't confirm";

close $fh;

$logger->called_ok("info");

