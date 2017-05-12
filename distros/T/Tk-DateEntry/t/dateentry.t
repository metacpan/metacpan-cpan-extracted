#!/usr/bin/perl 
# -*- perl -*-

use strict;
use FindBin;
use lib "$FindBin::RealBin";

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

use Getopt::Long;
use Tk;
use TkTest qw(catch_grabs);

my $mw = eval { MainWindow->new };
if (!$mw) {
    print "1..0 # skip: cannot create MainWindow: $@";
    exit;
}
$mw->geometry('+1+1');

my $dc_tests = 3;
plan tests => 2 + $dc_tests;

require_ok('Tk::DateEntry');

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }
GetOptions("demo" => sub { $ENV{BATCH} = 0 })
    or die "usage: $0 [-demo]";

my $can_date_calc = eval q{ use Date::Calc; 1 } || eval q{ use Date::Pcalc; 1 };

# Present german labels for german locale
my @extra_args;
if ((defined $ENV{LC_ALL} && $ENV{LC_ALL} =~ /^de/) ||
    (defined $ENV{LANG}   && $ENV{LANG}   =~ /^de/)) {
    @extra_args = (-weekstart => 1,
		   #-daynames => [qw/So Mo Di Mi Do Fr Sa/],
		   -daynames => 'locale',
		   -parsecmd => sub {
		       my($d,$m,$y) = ($_[0] =~ m/(\d*)\.(\d*)\.(\d*)/);
		       return ($y,$m,$d);
		   },
		   -formatcmd => sub {
		       sprintf ("%02d.%02d.%04d",$_[2],$_[1],$_[0]);
		   },
		  );
}

my $arrowdownwin = $mw->Photo(-data => <<'EOF');
#define arrowdownwin2_width 9
#define arrowdownwin2_height 13
static char arrowdownwin2_bits[] = {
 0x00,0xfe,0x00,0xfe,0x00,0xfe,0x00,0xfe,0x00,0xfe,0x7c,0xfe,0x38,0xfe,0x10,
 0xfe,0x00,0xfe,0x00,0xfe,0x00,0xfe,0x00,0xfe,0x00,0xfe};
EOF

$mw->Label(-text=>'Select date:')->pack(-side=>'left');
my $date;
my $de = $mw->DateEntry(-textvariable => \$date,
			-todaybackground => "green",
			-arrowimage => $arrowdownwin,
			@extra_args,
			-configcmd => \&configcmd,
		       )->pack(-side=>'left');

if ($ENV{BATCH}) {
    $mw->update; $mw->after(200);
    # The used members are internals, do not use in regular programs!
    $mw->after(200, sub {
		   $de->{_backbutton}->invoke;
	       });
    $mw->after(700, sub {
		   $de->{_nextbutton}->invoke;
	       });
    $mw->after(1200, sub {
		   $de->{_daybutton}->[2]->[3]->invoke;
	       });
    my $no_grab_error = catch_grabs {
	$de->buttonDown;
	$mw->update;
	# This blocks until a date is clicked
	like($date, qr/\d/, "Got date <$date>");
    } 1;

 SKIP: {
	skip("No Date::(P)Calc available", $dc_tests) if !$can_date_calc;
	skip("grab error encountered, will not continue with tests", $dc_tests) if !$no_grab_error;

	my $old_date = $de->Callback('-formatcmd', 1900, 1, 1);
	$date = $old_date;
	$mw->after(200, sub {
		       $de->{_backbutton}->invoke;
		   });
	$mw->after(700, sub {
		       if ($de->cget('-weekstart') == 1) {
			   $de->{_daybutton}->[2]->[3]->invoke;
		       } else {
			   $de->{_daybutton}->[2]->[4]->invoke;
		       }
		   });
	catch_grabs {
	    $de->buttonDown;
	    $mw->update;
	    my($y,$m,$d) = $de->Callback('-parsecmd', $date);
	    is($d, 14, "Expected day");
	    is($m, 12, "Expected month");
	    is($y, 1899, "Expected year");
	} 3;
    }

} else {
    $mw->Button(-text => 'OK',
		-command => sub {
		    pass("Selected date: $date");
		    $mw->destroy;
		})->pack;
 SKIP: {
	skip("No Date::Calc-related tests in interactive mode", $dc_tests);
    }
    MainLoop;
}

sub configcmd {
    my(%args) = @_;
    if ($args{-date}) {
	my($d,$m,$y) = @{ $args{-date} };
	my $dw = $args{-datewidget};
	if ($d == 1) {
	    $dw->configure(-bg => "red", -fg => "white");
	} else {
	    $dw->configure(-bg => "grey80", -fg => "black");
	}
	#warn "$d $m $y";
    }
}
