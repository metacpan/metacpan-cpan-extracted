use strict;
use warnings;
use utf8;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Images;

# App::ansipic::ansipic is the command as a function: it takes the
# arguments and returns the status, and does not exit, so that
# Command::Run can call it, with or without a fork.  Command::Run does
# not take the value returned: the messages tell what went wrong.

BEGIN {
    eval { require Command::Run; 1 } or plan skip_all => 'no Command::Run';
}
use App::ansipic;

my $dir = tempdir(CLEANUP => 1);
my $tty = "$dir/tty";
my $a = png("$dir/a.png", 64, 68);	# 4 x 2 cells
my @kitty = ('-m', 'kitty', '--term', '80x24:16x34', '--tty', $tty);
sub placeholders { my $n = () = $_[0] =~ /\x{10EEEE}/g; $n }

for my $nofork (0, 1) {
    my $mode = $nofork ? 'nofork' : 'fork';
    unlink $tty;
    my $r = Command::Run->new(
	command => [ \&App::ansipic::ansipic, @kitty, $a ],
	nofork  => $nofork,
    )->run;
    is($r->{result}, 0, "$mode: status 0");
    is(placeholders($r->{data}), 8, "$mode: the rows of the image");
    ok(-s $tty, "$mode: the image is sent");

    $r = Command::Run->new(
	command => [ \&App::ansipic::ansipic, @kitty, "$dir/missing.png" ],
	stderr  => 'capture',
	nofork  => $nofork,
    )->run;
    like($r->{error}, qr/missing\.png: not found/, "$mode: a file not shown is told");

    $r = Command::Run->new(
	command => [ \&App::ansipic::ansipic, @kitty, '-t', 'svg', $a ],
	stderr  => 'capture',
	nofork  => $nofork,
    )->run;
    like($r->{error}, qr/unknown type: svg/, "$mode: an error is told");

    $r = Command::Run->new(command => [ \&App::ansipic::ansipic, '--version' ], nofork => $nofork)->run;
    like($r->{data}, qr/^ansipic \d/, "$mode: --version returns");
}

# the status, returned by the function
{
    open my $save, '>&', \*STDERR or die;
    open STDERR, '>', File::Spec->devnull or die;
    my @status = (
	App::ansipic::ansipic(@kitty, "$dir/missing.png"),
	App::ansipic::ansipic(@kitty, '-t', 'svg', $a),
	App::ansipic::ansipic(@kitty),
    );
    open STDERR, '>&', $save or die;
    is_deeply(\@status, [ 1, 2, 2 ], 'status: 1 for a file not shown, 2 for an error');
}

# called again, the function starts over
{
    my $runner = Command::Run->new(command => [ \&App::ansipic::ansipic, @kitty ], nofork => 1);
    my $r1 = $runner->run(command => [ \&App::ansipic::ansipic, @kitty, '-w', '2', $a ]);
    my $r2 = $runner->run(command => [ \&App::ansipic::ansipic, @kitty, $a ]);
    is(placeholders($r1->{data}), 2, 'first: -w 2');
    is(placeholders($r2->{data}), 8, 'second: no -w left');
}

done_testing;
