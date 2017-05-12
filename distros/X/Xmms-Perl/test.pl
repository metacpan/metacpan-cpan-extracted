use strict;
use ExtUtils::testlib;
use Xmms ();
use Xmms::Remote ();
use Xmms::Config ();
use Test;
use Cwd qw(fastcwd);

my $pwd = fastcwd;

my $remote = Xmms::Remote->new;
my $config = Xmms::Config->new(Xmms::Config->file);

my $Pid = 0;
unless ($remote->is_running) {
    exec "xmms" unless $Pid = fork;
    sleep 1;
}

my $op = $config->read(xmms => 'output_plugin');

if ($op =~ /disk_writer/) {
    print <<EOF;
Your Output plugin is set to disk_writer, which is probably not what you want.
I\'ll pop up the preferences window for you to change.
Afterwards, close xmms and run 'make test' again.
EOF
    $remote->show_prefs_box;
    print "1..0\n";
    exit;
}

unless ($remote->get_version) {
    print "1..0\n";
    exit;
}

plan tests => 10;

ok $remote->is_running;
ok $remote->get_version;

my $orig_files = $remote->get_playlist_files;
my $orig_pos = $remote->get_playlist_pos;
my $orig_time = $remote->get_output_time;

if ($remote->is_playing) {
    #$remote->stop;
}

$remote->playlist_clear;
Xmms::sleep(0.25);
$remote->playlist([map { "$pwd/test$_.mp3" } (1..3)]);
Xmms::sleep(0.25);

#$remote->set_playlist_pos(0);
$remote->play;

ok $remote->get_playlist_length;
#ok $remote->get_playlist_pos;

my($vl, $vr) = $remote->get_volume;
$remote->set_main_volume(25);
ok $vl;
ok $vr;
if ($remote->is_repeat) {
    $remote->toggle_repeat;
}
if ($remote->is_shuffle) {
    $remote->toggle_shuffle;
}

sleep 1;

my($rate, $freq, $nch) = $remote->get_info;
#ok ($rate && $freq && $nch) || 1; #hmm
ok $remote->get_playlist_file(0);
ok $remote->get_playlist_time(0);

#$remote->set_volume($vl, $vr);

my $b = $remote->get_balance;

my $skin = $remote->get_skin;

for (1, 0) {
    #$remote->toggle_aot($_);
}

for (1, 0) {
    $remote->main_win_toggle($_);
    $remote->pl_win_toggle($_);
    $remote->eq_win_toggle($_);
    sleep 1;
}

for (1,2) {
    sleep 1;
    my $time = $remote->get_output_time;
    ok $time || 1; #hmm
}

$remote->main_win_toggle(1);

#hmm, we attempt to toggle repeat off above, by reading the config value,
#but if xmms is already running, it may have been changed
{
    local $SIG{ALRM} = sub {die};
    alarm 10;
    eval {
	while($remote->is_playing) {
	    $remote->set_balance(-30);
	    sleep 2;
	    $remote->set_main_volume(30);
	}
    };
    alarm 0;
}

$remote->set_balance(0);
$remote->stop;

Xmms::sleep(0.25);
ok !$remote->is_playing;

$remote->quit if $Pid;

#as you were
if (@$orig_files) {
    $remote->playlist($orig_files);
    $remote->set_playlist_pos($orig_pos);
    Xmms::sleep(0.25);
    $remote->jump_to_time($orig_time);
}
