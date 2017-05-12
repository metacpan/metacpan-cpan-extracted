use strict;
use Test::More;

use Cwd qw(getcwd);

use Xymon::Plugin::Server::Status qw(:colors);
use Xymon::Plugin::Server::Devmon;

sub test_bb_runnable {
    return unless (-f "/bin/sh");
    return (-f "/bin/cat" || -f "/usr/bin/cat");
}

unless (test_bb_runnable) {
    plan skip_all => 'dummy bb command is not runnable.'
}
else {
    plan tests => 30;
}

my $cwd = getcwd;

sub get_bb_cmdline {
    open my $fh, "<", "t/tmp/cmdline.txt" or return "*** ERROR ***";
    local $/;
    my $txt = <$fh>;
    return $txt;
}

sub get_bb_input {
    open my $fh, "<", "t/tmp/input.txt" or return "*** ERROR ***";
    local $/;
    my $txt = <$fh>;
    return $txt;
}

#
# 4.2
#
local $ENV{BBHOME} = "$cwd/t/testhome42";
local $ENV{XYMONHOME};

{
    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    $st->report;

    my $cmdline = get_bb_cmdline;
    my $input = get_bb_input;

    # check bb command input
    ok($cmdline =~ /^127\.0\.0\.1 \@/);
    ok($input =~ /^status host1.test2 clear/);
}

# test simple colors
{
    for my $c (GREEN, YELLOW, RED) {
	my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
	$st->add_status($c);
	$st->report;

	my $cmdline = get_bb_cmdline;
	my $input = get_bb_input;

	# check bb command input
	ok($cmdline =~ /^127\.0\.0\.1 \@/);

	my %cdic = (GREEN, "green", YELLOW, "yellow", RED, "red");
	my $color = $cdic{$c};
	my $okstr = $c eq GREEN ? '- OK' : '- NOT OK';
	ok($input =~ /^status host1.test2 $color .* $okstr\n/);
    }
}

{

    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    $st->add_status(GREEN, "green test");
    $st->add_status(YELLOW, "yellow test");
    $st->report;

    my $input = get_bb_input;
    ok($input =~ /^status host1.test2 yellow/);
    ok($input =~ /\n&green green test/);
    ok($input =~ /\n&yellow yellow test/);
}

{

    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    $st->add_status(RED, "red test");
    $st->add_status(GREEN, "green test");
    $st->report;

    my $input = get_bb_input;
    ok($input =~ /^status host1.test2 red/);
    ok($input =~ /\n&red red test/);
    ok($input =~ /\n&green green test/);
}

{

    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    $st->add_status(RED, "red test");
    $st->add_status(YELLOW, "yellow test");
    $st->report;

    my $input = get_bb_input;
    ok($input =~ /^status host1.test2 red/);
    ok($input =~ /\n&red red test/);
    ok($input =~ /\n&yellow yellow test/);
}

{

    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    $st->add_status(GREEN, "green test1");
    $st->add_status(GREEN, "green test2");
    $st->add_message("diag message1");
    $st->add_message("diag message2");
    $st->report;

    my $input = get_bb_input;
    ok($input =~ /^status host1.test2 green/);
    ok($input =~ /\n&green green test1/);
    ok($input =~ /\n&green green test2/);

    ok($input =~ /\ndiag message1/);
    ok($input =~ /\ndiag message2/);
}

{

    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    $st->add_status(GREEN, "green test1");
    $st->add_message("diag message1");
    $st->add_graph("graph1");
    $st->report;

    my $input = get_bb_input;
    ok($input =~ /^status host1.test2 green/);
    ok($input =~ /\n&green green test1/);
    ok($input =~ /\ndiag message1/);
    ok($input =~ qr|\n<A HREF="/xymon-cgi/hobbitgraph.sh\?host=host1&amp;service=graph1&amp;graph_width=576&amp;graph_height=120&amp;disp=host1&amp;nostale&amp;color=green&amp;action=menu">\n+<IMG BORDER=0 SRC="/xymon-cgi/hobbitgraph.sh\?host=host1&amp;service=graph1&amp;graph_width=576&amp;graph_height=120&amp;disp=host1&amp;nostale&amp;color=green&amp;graph=hourly&amp;action=view">|);

    ok($input =~ /^status .*test1.*message1.*<A HREF/s);
}

{
    my $st = Xymon::Plugin::Server::Status->new("host1", "test2");
    my $devmon = Xymon::Plugin::Server::Devmon->new(x => 'GAUGE:600:0:U');
    $devmon->add_data(device1 => { x => 0 });

    $st->add_status(GREEN, "green test1");
    $st->add_devmon($devmon);
    $st->report;

    my $input = get_bb_input;
    ok($input =~ /^status host1.test2 green/);
    ok($input =~ /\n&green green test1/);
    ok($input =~ /^status .*test1.*\n<!--DEVMON.*\nDS:ds0/s);
}
