# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Tk;

package Tk::Widget;
sub eventGenerate2 {
    my $w = shift;
    my $e = shift;
    $w->eventGenerate($e, @_,
		      ($Tk::VERSION >= 800.016 ? (-warp => 1) : ()),
		     );
    if ($main::SLOW) {
	warn "Event: $e => $w\n";
	$w->update;
	sleep $main::SLOW;
    }
}

package main;
use Tk::Date;
use strict;
use vars qw($loaded $SLOW);

my $top;
BEGIN {
    if (!eval { $top = MainWindow->new }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

BEGIN { $| = 1; $^W = 1; print "1..39\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
my $ok = 1;
$SLOW = 1;
print "ok " . $ok++ . "\n";

BEGIN {

    package Tk::Date::MyDate;
    # a custom date format: YYYYMMDD

    sub TIESCALAR {
	my($class, $w, $init) = @_;
	my $self = {};
	$self->{Widget} = $w;
	bless $self, $class;
	if (defined $init) {
	    $self->STORE($init);
	}
	$self;
    }

    sub STORE {
	my($self, $value) = @_;
#	warn "STORE: $value";
	my($y, $m, $d) = (substr($value, 0, 4),
			  substr($value, 4, 2),
			  substr($value, 6, 2));
	$self->{Widget}->set_date('y', $y);
	$self->{Widget}->set_date('m', $m);
	$self->{Widget}->set_date('d', $d);
    }

    sub FETCH {
	my $self = shift;
	my $value = sprintf("%04d%02d%02d",
			    $self->{Widget}->get_date('y'),
			    $self->{Widget}->get_date('m'),
			    $self->{Widget}->get_date('d'),
			   );
#	warn "FETCH: $value";
	$value;
    }

}

$top->geometry("+0+0");

my $dw = $top->Date->pack;
print ((ref $dw ne 'Tk::Date' ? "not " : "") . "ok " . $ok++ . "\n");

$dw->configure(-value => 'now');
my $now1 = $dw->get("%s");
my $now2 = time;
my $delta = abs($now2-$now1);
print (($delta > 2 ? "not " : "") . "ok " . $ok++ . "\n");

my $var2;
my $dw2 = $top->Date(-varfmt => 'unixtime',
		     -variable => \$var2,
		     -value => 'now',
		    )->pack;
$now2 = time;
$delta = abs($now2-$var2);
print (($delta > 2 ? "not " : "") . "ok " . $ok++ . "\n");

{
    # Test: -fields => 'time' and -varfmt => 'datehash' with tied variable

    my(%date) = (H => 1, M => 2, S => 3);
    $top->Date(-varfmt => 'datehash',
	       -variable => \%date,
	       -fields => 'time')->pack;
    if (join(":", @date{qw(H M S)}) ne "01:02:03") {
	print "not ";
    }
    print "ok " . $ok++ . "\n";
}

eval { require POSIX };
if ($@) {
    print "ok " . $ok++ . " # skip POSIX required\n";
} else {
    eval {
	my $var3 = {};
	my $dw3 = $top->Date(-varfmt => 'datehash',
			     -variable => $var3,
			     -value => 'now',
			    )->pack;
	$now1 = POSIX::mktime(@{$var3}{qw(S M H d)},
			      $var3->{'m'}-1, $var3->{'y'}-1900,
			      0, 0, -1
			     );
	$now2 = time;
	$delta = abs($now2-$now1);
    };
    print (($delta > 2 || $@ ? "not " : "") . "ok " . $ok++ . "\n");
}

my $var4;
my $dw4 = $top->Date(-varfmt => 'Tk::Date::MyDate',
		     -variable => \$var4,
		     -value => 'now',
		    )->pack;
my(@now) = localtime;
my $nowstring = sprintf("%04d%02d%02d", $now[5]+1900, $now[4]+1, $now[3]);
print (($nowstring ne $var4 ? "not " : "" . "ok ") . $ok++ . "\n");

{
    # test widget with only time field
    my $dw_time = $top->Date(-fields => 'time', -value => 'now')->pack;
    if (!$dw_time->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    my $nowtime = time;
    my $s = $dw_time->get;
    my $delta = abs($nowtime-$s);
    if ($delta > 2) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    $nowtime = time;
    $s = $dw_time->get("%s");
    $delta = abs($nowtime-$s);
    if ($delta > 2) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    if ($^O !~ /^(freebsd|linux)$/) {
	print "ok " . ($ok++) . " # skip Test only works on FreeBSD or Linux\n";
    } else {
	$dw_time->get("%+"); # not supported everywhere
	print "ok " . ($ok++) . "\n";
    }
}

{
    # test widget with only date field
    my $dw_time = $top->Date(-fields => 'date', -value => 'now')->pack;
    if (!$dw_time->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";


    my $nowtime = time;
    my $s = $dw_time->get;
    my $delta = abs($nowtime-$s);
    if ($delta > 2) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    $nowtime = time;
    $s = $dw_time->get("%s");
    $delta = abs($nowtime-$s);
    if ($delta > 2) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    if ($^O !~ /^(freebsd|linux)$/) {
	print "ok " . ($ok++) . " # skip Test only works on FreeBSD or Linux\n";
    } else {
	$dw_time->get("%+"); # not supported everywhere
	print "ok " . ($ok++) . "\n";
    }
}

{
    # test -choices option
    my $dw_time = $top->Date(-fields => 'both',
			     -value => 'now',
			     -choices => [qw(today yesterday tomorrow)],
			    )->pack;
    my($x, $y) = center2($dw_time);
    if (!$dw_time->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    if (!defined $dw_time->Subwidget('chooser')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    if (0) {
    # XXX eventGenerate geht nicht mit Menubutton (?)
    $dw_time->Subwidget('chooser')->eventGenerate2('<ButtonPress-1>', '-x' => $x, '-y' => $y);
    $dw_time->update;
#warn $dw_time->get("%s");
#warn Tk::Date::_begin_of_day(time());
    if ($dw_time->get("%s") != Tk::Date::_begin_of_day(time())) {
	print "not ";
    }
    print " ok " . ($ok++) . "\n";
    }
}

{
    # test -command and -precommand
    my(@command, @precommand);
    my $cmd = sub {
	@command = @_;
    };
    my $precmd = sub {
	@precommand = @_;
	1;
    };

    my $d = $top->Date(-command => $cmd,
		       -precommand => $precmd,
		       -choices => ['today', 'yesterday'],
		      )->pack;
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    my @fb = (@{$d->{IncFireButtons}},
	      @{$d->{DecFireButtons}});
    if (@fb and @fb == 4) {
	foreach my $def ([0, 'date', 1],
			 [1, 'time', 1],
			 [2, 'date', -1],
			 [3, 'time', -1]) {
	    @command = ();
	    @precommand = ();
	    $fb[$def->[0]]->invoke;
	    if (!(ref $command[0] eq 'Tk::Date' &&
		  ref $precommand[0] eq 'Tk::Date' &&
		  $command[1] eq $def->[1] &&
		  $precommand[1] eq $def->[1] &&
		  $command[2] == $def->[2] &&
		  $precommand[2] == $def->[2])) {
		print "not ";
	    }
	    print "ok " . ($ok++) . "\n";
	}
	@command = ();
	$d->Subwidget('chooser')->cget(-menu)->invoke(1);
	if (!(ref $command[0] eq 'Tk::Date')) {
	    print "not ";
	}
	print "ok " . ($ok++) . "\n";
    } else {
	for (1 .. 5) {
	    print "ok " . ($ok++) . " # skip Probably no Tk::FireButton installed\n";
	}
    }
}

{
    # test -command with a single choices entry
    my(@command);
    my $cmd = sub {
	@command = @_;
    };

    my $d = $top->Date(-command => $cmd,
		       -choices => 'today',
		      )->pack;
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    @command = ();
    $d->Subwidget('chooserbutton')->invoke;
    if (!(ref $command[0] eq 'Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

}

{
    # test -weekdays, -monthnames and -monthmenu
    my $d = $top->Date(-weekdays => 
		       ['nedjelja', 'ponedjeljak', 'utorak', 'srijeda',
			'cetvrtak', 'petak', 'subota'],
		       -monthnames =>
		       ['sijecanj', 'veljaca', 'ozujak', 'travanj',
			'svibanj', 'lipanj', 'srpanj', 'kolovoz', 'rujan',
			'listopad', 'studeni', 'prosinac'],
		       -monthmenu => 1,
		       );
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    if ($d->{Configure}{-weekdays}->[0] ne 'nedjelja') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    if ($d->{Configure}{-monthnames}->[0] ne 'sijecanj') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
}

{
    # test -readonly
    my $d = $top->Date(-readonly => 1);
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
}

{
    # test -state
    my $d = $top->Date(-state => "disabled");
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    if ($d->cget(-state) ne 'disabled') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    $d->configure(-state => "normal");
    if ($d->cget(-state) ne 'normal') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
}

{
    # test -state together with -editable
    my $d = $top->Date(-editable => 0);
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    $d->configure(-state => 'disabled');
    if ($d->cget(-state) ne 'disabled') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    $d->configure(-state => "normal");
    if ($d->cget(-state) ne 'normal') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

}

my $weekdays = Tk::Date::_get_week_days;
if (scalar @$weekdays != 7) { print "not " } print "ok " . ($ok++) . "\n";

my $monthnames = Tk::Date::_get_month_names;
if (scalar @$monthnames != 12) { print "not " } print "ok " . ($ok++) . "\n";

{
    # test invalid date handling
    my $d = $top->Date(-value => 'now');
    if (!$d->isa('Tk::Date')) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
    $d->{Sub}{'d'}->delete(0,"end");
    $d->{Sub}{'d'}->insert("end",39);
    $d->set_date('d', 40);
    if ($d->get('%d') ne '01') {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
}

sub center2 {
    my($wid) = @_;
    $wid->idletasks;
    my($w, $h) = ($wid->width, $wid->height);
    (int($w/2), int($h/2));
}

