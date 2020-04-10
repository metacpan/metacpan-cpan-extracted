#!/pro/bin/perl

package Tk::Clock;

use strict;
use warnings;

our $VERSION = "0.41";

use Carp;

use Tk;
use Tk::Widget;
use Tk::Derived;
use Tk::Canvas;

use vars qw( @ISA );
@ISA = qw/Tk::Derived Tk::Canvas/;

Construct Tk::Widget "Clock";

my $ana_base = 73;	# Size base for 100%

my %def_config = (
    timeZone	=> "",
    useLocale	=> "C",
    backDrop	=> "",

    useAnalog	=> 1,

    handColor	=> "Green4",
    secsColor	=> "Green2",
    tickColor	=> "Yellow4",
    tickFreq	=> 1,
    tickDiff	=> 0,
    useSecHand	=> 1,
    handCenter	=> 0,

    anaScale	=> 100,
    autoScale	=> 0,

    ana24hour	=> 0,
    countDown	=> 0,
    timerValue	=> 0,
    localOffset	=> 0,

    useInfo	=> 0,

    infoColor	=> "#cfb53b",
    infoFormat	=> "HH:MM:SS",
    infoFont	=> "fixed 6",

    useDigital	=> 1,

    digiAlign	=> "center",

    timeFont	=> "fixed 6",
    timeColor	=> "Red4",
    timeFormat	=> "HH:MM:SS",

    dateFont	=> "fixed 6",
    dateColor	=> "Blue4",
    dateFormat	=> "dd-mm-yy",

    fmtd	=> sub {
	sprintf "%02d-%02d-%02d", $_[3], $_[4] + 1, $_[5] + 1900;
	},
    fmtt	=> sub {
	sprintf "%02d:%02d:%02d", @_[2,1,0];
	},
    fmti	=> sub {
	sprintf "%02d:%02d:%02d", @_[2,1,0];
	},

    _anaSize	=> $ana_base,	# Default size (height & width)
    _digSize	=> 26,		# Height
    _digWdth	=> 72,		# Width
    );

my %locale = (
    C	=> {
      month	=> [
	#   m    mm    mmm    mmmm
	[  "1", "01", "Jan", "January"	],
	[  "2", "02", "Feb", "February"	],
	[  "3", "03", "Mar", "March"	],
	[  "4", "04", "Apr", "April"	],
	[  "5", "05", "May", "May"	],
	[  "6", "06", "Jun", "June"	],
	[  "7", "07", "Jul", "July"	],
	[  "8", "08", "Aug", "August"	],
	[  "9", "09", "Sep", "September"],
	[ "10", "10", "Oct", "October"	],
	[ "11", "11", "Nov", "November"	],
	[ "12", "12", "Dec", "December"	],
	],
      day	=> [
	#  ddd    dddd
	[ "Sun", "Sunday"		],
	[ "Mon", "Monday"		],
	[ "Tue", "Tuesday"		],
	[ "Wed", "Wednesday"		],
	[ "Thu", "Thursday"		],
	[ "Fri", "Friday"		],
	[ "Sat", "Saturday"		],
	],
      },
    );

sub _booleans {
    my $data = shift;
    $data->{$_} = !!$data->{$_} for qw(
	ana24hour
	autoScale
	countDown
	handCenter
	useAnalog
	useDigital
	useInfo
	useSecHand
	);
    } # _booleans

sub _decode {
    my $s = shift;
    $s && $s =~ m{[\x80-\xff]} or return $s;
    my $u = eval { Encode::decode ("UTF-8", $s, Encode::FB_CROAK) };
    return ($@ ? $s : $u);
    } # _decode

sub _newLocale {
    my $locale = shift or return $locale{C};

    require POSIX;
    require Encode;

    my $curloc = POSIX::setlocale (POSIX::LC_TIME (), "")      || "C";
    my $newloc = POSIX::setlocale (POSIX::LC_TIME (), $locale) || "C";
    $locale{$newloc} and return $locale{$newloc};

    my $l = $locale{$locale} = {};
    foreach my $m (0 .. 11) {
	@{$l->{month}[$m]} = map { _decode ($_) }
	    $m + 1, $locale{C}{month}[$m][1],
	    POSIX::strftime ("%b", 0, 0, 0, 1, $m, 113),
	    POSIX::strftime ("%B", 0, 0, 0, 1, $m, 113);
	}
    foreach my $d (0 .. 6) {
	@{$l->{day}[$d]}   = map { _decode ($_) }
	    POSIX::strftime ("%a", 0, 0, 0, $d - 1, 0, 113),
	    POSIX::strftime ("%A", 0, 0, 0, $d - 1, 0, 113);
	}

    POSIX::setlocale (POSIX::LC_TIME (), $curloc);

    return $l;
    } # _newLocale

sub _month {	# (month, size)
    my ($locale, $m, $l) = @_;
    ($locale{$locale} || $locale{C})->{month}[$m][$l];
    } # _month

sub _wday {	# (wday, size)
    my ($locale, $m, $l) = @_;
    ($locale{$locale} || $locale{C})->{day}[$m][$l];
    } # _wday

sub _min {
    $_[0] <= $_[1] ? $_[0] : $_[1];
    } # _min

sub _max {
    $_[0] >= $_[1] ? $_[0] : $_[1];
    } # _max

# Transparent packInfo for pack/grid/place/form
sub _packinfo {
    my $clock = shift;

    my %pi = map { ("-$_" => 0) } qw( padx pady ipadx ipady );
    if (my $pm = $clock->manager) {
	   if ($pm eq "pack") {
	    %pi = $clock->packInfo;
	    }
	elsif ($pm eq "grid") {
	    %pi = $clock->gridInfo;
	    }
	elsif ($pm eq "form") {
	    %pi = $clock->formInfo;
	    # padx pady padleft padright padtop padbottom
	    $pi{"-ipadx"} = int (((delete $pi{"-padleft"}) + (delete $pi{"-padright"} )) / 2);
	    $pi{"-ipady"} = int (((delete $pi{"-padtop"} ) + (delete $pi{"-padbottom"})) / 2);
	    }
	elsif ($pm eq "place") {
	    # No action, place has no padding
	    }
	else {
	    # No action, unknown geometry manager
	    }
	}
    %pi;
    } # _packinfo

sub _resize {
    my $clock = shift;

    use integer;
    my $data = $clock->privateData;
    my $hght = $data->{useAnalog}  * $data->{_anaSize} +
	       $data->{useDigital} * $data->{_digSize} + 1;
    my $wdth = _max ($data->{useAnalog}  * $data->{_anaSize},
		     $data->{useDigital} * $data->{_digWdth});
    my $dim  = "${wdth}x${hght}";
    my $geo   = $clock->parent->geometry;
    my ($pw, $ph) = split m/\D/, $geo; # Cannot use ->cget here
    if ($ph > 5 && $clock->parent->isa ("MainWindow")) {
	my %pi = $clock->_packinfo;
	my $px = _max ($wdth + $pi{"-padx"}, $pw);
	my $py = _max ($hght + $pi{"-pady"}, $ph);
	$clock->parent->geometry ("${px}x$py");
	}
    $clock->configure (
	-height => $hght,
	-width  => $wdth);
    $dim;
    } # _resize

# Callback when auto-resize is called
sub _resize_auto {
    my $clock = shift;
    my $data  = $clock->privateData;

    $data->{useAnalog} && $data->{autoScale} == 1 or return;

    my $owdth = $data->{useAnalog} * $data->{_anaSize};
    my $geo   = $clock->geometry;
    my ($gw, $gh) = split m/\D/, $geo; # Cannot use ->cget here
    $gw < 5 and return; # not packed yet?
    $data->{useDigital} and $gh -= $data->{_digSize};
    my $nwdth = _min ($gw, $gh - 1);
    abs ($nwdth - $owdth) > 5 && $nwdth >= 10 or return;

    $data->{_anaSize} = $nwdth - 2;
    $clock->_destroyAnalog;
    $clock->_createAnalog;
    if ($data->{useDigital}) {
	# Otherwise the digital either overlaps the analog
	# or there is a gap
	$clock->_destroyDigital;
	$clock->_createDigital;
	}
    $clock->_resize;
    } # _resize_auto

sub _createDigital {
    my $clock = shift;

    my $data = $clock->privateData;

    # Dynamically determine the size of the digital display
    my @t = localtime (time + $data->{localOffset});
    my ($wd, $hd) = do {
	my $s_date = $data->{fmtd}->(@t, 0, 0, 0);
	$s_date =~ s/\b([0-9])\b/0$1/g; # prepare "d" running from 9 to 10
	my $f  = $clock->Label (-font => $data->{dateFont})->cget (-font);
	my %fm = $clock->fontMetrics ($f);
	($clock->fontMeasure ($f, $s_date), $fm{"-linespace"} || 9);
	};
    my ($wt, $ht) = do {
	my $s_time = $data->{fmtt}->(@t, 0, 0, 0);
	$s_time =~ s/\b([0-9])\b/0$1/g; # prepare "h" running from 9 to 10
	my $f  = $clock->Label (-font => $data->{timeFont})->cget (-font);
	my %fm = $clock->fontMetrics ($f);
	($clock->fontMeasure ($f, $s_time), $fm{"-linespace"} || 9);
	};
    my $w = _max (72, int (1.1 * _max ($wt, $wd)));
    $data->{_digSize} = $hd + 4 + $ht + 4; # height of date + time
    $data->{_digWdth} = $w;

    my $wdth = _max ($data->{useAnalog}  * $data->{_anaSize},
		     $data->{useDigital} * $w);
    my ($pad, $anchor) = (5, "s");
    my ($x, $y) = ($wdth / 2, $data->{useAnalog} * $data->{_anaSize});
    if    ($data->{digiAlign} eq "left") {
	($anchor, $x) = ("sw", $pad);
	}
    elsif ($data->{digiAlign} eq "right") {
	($anchor, $x) = ("se", $wdth - $pad);
	}
    $clock->createText ($x, $y + $ht + 4 + $hd,
	-anchor	=> $anchor,
	-width  => ($wdth - 2 * $pad),
	-font   => $data->{dateFont},
	-fill   => $data->{dateColor},
	-text   => $data->{dateFormat},
	-tags   => "date");
    $clock->createText ($x, $y + $ht + 2,
	-anchor	=> $anchor,
	-width  => ($wdth - 2 * $pad),
	-font   => $data->{timeFont},
	-fill   => $data->{timeColor},
	-text   => $data->{timeFormat},
	-tags   => "time");
#   $data->{Clock_h} = -1;
#   $data->{Clock_m} = -1;
#   $data->{Clock_s} = -1;
    $clock->_resize;
    } # _createDigital

sub _destroyDigital {
    my $clock = shift;

    $clock->delete ("date");
    $clock->delete ("time");
    } # _destroyDigital

sub _where {
    my ($clock, $tick, $len, $anaSize) = @_;      # ticks 0 .. 59
    my ($x, $y, $angle);

    $clock->privateData->{countDown} and $tick = (60 - $tick) % 60;
    my $h = ($anaSize + 1) / 2;
    $angle = $tick * .104720;
    $x = $len  * sin ($angle) * $anaSize / 73;
    $y = $len  * cos ($angle) * $anaSize / 73;
    ($h - $x / 4, $h + $y / 4, $h + $x, $h - $y);
    } # _where

sub _createAnalog {
    my $clock = shift;

    my $data = $clock->privateData;

    ref $data->{backDrop} eq "Tk::Photo" and
	$clock->createImage (0, 0,
	    -anchor => "nw",
	    -image  => $data->{backDrop},
	    -tags   => "back",
	    );

    my $h = ($data->{_anaSize} + 1) / 2 - 1;

    if ($data->{useInfo}) {
	$clock->createText ($h, int (1.3 * $h),
	    -anchor => "n",
	    -width  => int (1.2 * $h),
	    -font   => $data->{infoFont},
	    -fill   => $data->{infoColor},
	    -text   => $data->{infoFormat},
	    -tags   => "info");
	}

    my $f = $data->{tickFreq} * 2;
    foreach my $dtick (0 .. 119) {
	$dtick % $f and next;
	my $l = $dtick % 30 == 0 ? $h / 5 :
		$dtick % 10 == 0 ? $h / 8 :
				   $h / 16;
	my $angle = ($dtick / 2) * .104720;
	my $x = sin $angle;
	my $y = cos $angle;
	$clock->createLine (
	    ($h - $l) * $x + $h + 1, ($h - $l) * $y + $h + 1,
	     $h       * $x + $h + 1,  $h       * $y + $h + 1,
	    -tags  => "tick",
	    -arrow => "none",
	    -fill  => $data->{tickColor},
	    -width => $data->{tickDiff} && $dtick % 10 == 0 ? 4.0 : 1.0,
	    );
	}
    $data->{Clock_h} = -1;
    $data->{Clock_m} = -1;
    $data->{Clock_s} = -1;

    $clock->createLine (
	$clock->_where (0, 22, $data->{_anaSize}),
	    -tags  => "hour",
	    -arrow => "none",
	    -fill  => $data->{handColor},
	    -width => $data->{_anaSize} / ($data->{handCenter} ? 35 : 26),
	    );
    if ($data->{handCenter}) {
	my $cntr = $data->{_anaSize} /  2;
	my $diam = $data->{_anaSize} / 30;
	$clock->createOval (($cntr - $diam) x 2, ($cntr + $diam) x 2,
	    -tags  => "hour",
	    -fill  => $data->{handColor},
	    -width => 0,
	    );
	}
    $clock->createLine (
	$clock->_where (0, 30, $data->{_anaSize}),
	    -tags  => "min",
	    -arrow => "none",
	    -fill  => $data->{handColor},
	    -width => $data->{_anaSize} / ($data->{handCenter} ? 60 : 30),
	    );
    if ($data->{useSecHand}) {
	$clock->createLine (
	    $clock->_where (0, 34, $data->{_anaSize}),
		-tags  => "sec",
		-arrow => "none",
		-fill  => $data->{secsColor},
		-width => 0.8);
	if ($data->{handCenter}) {
	    my $cntr = $data->{_anaSize} /  2;
	    my $diam = $data->{_anaSize} / 35;
	    $clock->createOval (($cntr - $diam) x 2, ($cntr + $diam) x 2,
		-tags  => "sec",
		-fill  => $data->{secsColor},
		-width => 0,
		);
	    }
	}

    $clock->_resize;
    } # _createAnalog

sub _destroyAnalog {
    my $clock = shift;

    $clock->delete ($_) for qw( back info tick hour min sec );
    } # _destroyAnalog

sub Populate {
    my ($clock, $args) = @_;

    my $data = $clock->privateData;
    %$data = %def_config;
    $data->{Clock_h} = -1;
    $data->{Clock_m} = -1;
    $data->{Clock_s} = -1;
    $data->{_time_}  = -1;

    if (ref $args eq "HASH") {
	foreach my $arg (keys %$args) {
	    (my $attr = $arg) =~ s/^-//;
	    $attr =~ m/^_/ and next; # Internal use only!
	    exists $data->{$attr} and $data->{$attr} = delete $args->{$arg};
	    }
	}
    _booleans ($data);

    $clock->SUPER::Populate ($args);

    $clock->ConfigSpecs (
        -width              => [ qw(SELF width              Width              72    ) ],
        -height             => [ qw(SELF height             Height             100   ) ],
        -relief             => [ qw(SELF relief             Relief             raised) ],
        -borderwidth        => [ qw(SELF borderWidth        BorderWidth        1     ) ],
        -highlightthickness => [ qw(SELF highlightThickness HighlightThickness 0     ) ],
        -takefocus          => [ qw(SELF takefocus          Takefocus          0     ) ],
        );

    $data->{useAnalog}  and $clock->_createAnalog;
    $data->{useDigital} and $clock->_createDigital;
    $clock->_resize;

    $clock->repeat (995, ["_run" => $clock]);
    } # Populate

my %attr_weight = (
    useDigital	=> 99980,
    digiAlign	=> 99985,
    useAnalog	=> 99990,
    useInfo	=> 99991,
    tickFreq	=> 99992,
    anaScale	=> 99995,
    useLocale	=>     1,
    );

sub config {
    my $clock = shift;

    ref $clock or croak "Bad method call";
    @_ or return;

    my $conf;
    if (ref $_[0] eq "HASH") {
	$conf = shift;
	}
    elsif (scalar @_ % 2 == 0) {
	my %conf = @_;
	$conf = \%conf;
	}
    else {
	croak "Bad hash";
	}

    my $data = $clock->privateData;
    my $pfmt = $] < 5.010 ? "s" : "s>";
    $attr_weight{$_} ||= unpack $pfmt, $_ for keys %def_config;

    my $autoScale;
    # sort, so the recreational attribute will be done last
    foreach my $conf_spec (
	    map  { $_->[0] }
	    sort { $a->[1] <=> $b->[1] }
	    map  { [ $_, $attr_weight{$_} ] }
	    keys %$conf) {
	(my $attr = $conf_spec) =~ s/^-//;
	$attr =~ m/^_/ and next; # Internal use only!
	defined $def_config{$attr} && defined $data->{$attr} or next;
	my $old = $data->{$attr};
	$data->{$attr} = $conf->{$conf_spec};
	if    ($attr eq "tickColor") {
	    $clock->itemconfigure ("tick", -fill => $data->{tickColor});
	    }
	elsif ($attr eq "handColor") {
	    $clock->itemconfigure ("hour", -fill => $data->{handColor});
	    $clock->itemconfigure ("min",  -fill => $data->{handColor});
	    }
	elsif ($attr eq "secsColor") {
	    $clock->itemconfigure ("sec",  -fill => $data->{secsColor});
	    }
	elsif ($attr eq "dateColor") {
	    $clock->itemconfigure ("date", -fill => $data->{dateColor});
	    }
	elsif ($attr eq "dateFont") {
	    $clock->itemconfigure ("date", -font => $data->{dateFont});
	    }
	elsif ($attr eq "timeColor") {
	    $clock->itemconfigure ("time", -fill => $data->{timeColor});
	    }
	elsif ($attr eq "timeFont") {
	    $clock->itemconfigure ("time", -font => $data->{timeFont});
	    }
	elsif ($attr eq "infoColor") {
	    $clock->itemconfigure ("info", -fill => $data->{infoColor});
	    }
	elsif ($attr eq "infoFont") {
	    $clock->itemconfigure ("info", -font => $data->{infoFont});
	    }
	elsif ($attr eq "useLocale") {
	    $locale{$data->{useLocale}} or _newLocale ($data->{useLocale});
	    }
	elsif ($attr eq "dateFormat" || $attr eq "timeFormat" || $attr eq "infoFormat") {
	    my %fmt = (
		"S"	=> '%d',	# 45
		"SS"	=> '%02d',	# 45
		"Sc"	=> '%02d',	# 45	countdown
		"M"	=> '%d',	# 7
		"MM"	=> '%02d',	# 07
		"Mc"	=> '%02d',	# 07	countdown
		"H"	=> '%d',	# 6
		"HH"	=> '%02d',	# 06
		"Hc"	=> '%02d',	# 06	countdown
		"h"	=> '%d',	# 6	AM/PM
		"hh"	=> '%02d',	# 06	AM/PM
		"A"	=> '%s',	# PM
		"d"	=> '%d',	# 6
		"dd"	=> '%02d',	# 06
		"ddd"	=> '%3s',	# Mon
		"dddd"	=> '%s',	# Monday
		"m"	=> '%d',	# 7
		"mm"	=> '%02d',	# 07
		"mmm"	=> '%3s',	# Jul
		"mmmm"	=> '%s',	# July
		"y"	=> '%d',	# 98
		"yy"	=> '%02d',	# 98
		"yyy"	=> '%04d',	# 1998
		"yyyy"	=> '%04d',	# 1998
		"w"	=> '%d',	# 28 (week)
		"ww"	=> '%02d',	# 28
		);
	    my $fmt = $data->{$attr};
	    $fmt =~ m{[\%\@\$]} and croak "%, \@ and \$ not allowed in $attr";
	    my $xfmt = join "|", reverse sort keys %fmt;
	    my @fmt = split m/\b($xfmt)\b/, $fmt;
	    my $args = "";
	    $fmt = "";
	    my $locale = $data->{useLocale} || "C";
	    foreach my $f (@fmt) {
		if (defined $fmt{$f}) {
		    $fmt .= $fmt{$f};
		    if ($f =~ m/^m+$/) {
			my $l = length ($f) - 1;
			$args .= ", Tk::Clock::_month (q{$locale}, \$m, $l)";
			}
		    elsif ($f =~ m/^ddd+$/) {
			my $l = length ($f) - 3;
			$args .= ", Tk::Clock::_wday (q{$locale}, \$wd, $l)";
			}
		    else {
			$args .= ', $' . substr ($f, 0, 1);
			$f =~ m/^[HMS]c/ and $args .= "c";
			$f =~ m/^y+$/    and
			    $args .= length ($f) < 3 ? " % 100" : " + 1900";
			}
		    }
		else {
		    $fmt .= $f;
		    }
		}
	    $data->{Clock_h} = -1;	# force update;
	    $data->{"fmt".substr $attr, 0, 1} = eval join "\n" =>
		 q[ sub							],
		 q[ {							],
		 q[     my ($S,  $M,  $H, $d, $m, $y, $wd, $yd, $dst,	],
		 q[ 	    $Sc, $Mc, $Hc) = @_;			],
		 q[     my $w = $yd / 7 + 1;				],
		 q[     my $h = $H % 12;				],
		 q[     my $A = $H > 11 ? "PM" : "AM";			],
		 # AM/PM users expect 12:15 AM instead of 00:15 AM
		 q[     $h ||= 12;					],
		qq[     sprintf qq!$fmt!$args;				],
		 q[     }						];
	    }
	elsif ($attr eq "timerValue") {
	    $data->{timerStart} = $data->{timerValue} ? time : undef;
	    }
	elsif ($attr eq "tickFreq") {
#	    $data->{tickFreq} < 1 ||
#	    $data->{tickFreq} != int $data->{tickFreq} and
#		$data->{tickFreq} = $old;
	    unless ($data->{tickFreq} == $old) {
		$clock->_destroyAnalog;
		$clock->_createAnalog;
		}
	    }
	elsif ($attr eq "autoScale") {
	    $autoScale = !!$data->{autoScale};
	    }
	elsif ($attr eq "anaScale") {
	    if ($data->{anaScale} eq "auto" or $data->{anaScale} <= 0) {
		$data->{autoScale} = 1;
		$data->{anaScale} = $clock
		    ? int (100 * $clock->cget (-height) / $ana_base) || 100
		    : 100;
		$data->{_anaSize} = int ($ana_base * $data->{anaScale} / 100.);
		}
	    else {
		defined $autoScale or $autoScale = 0;
		my $new_size = int ($ana_base * $data->{anaScale} / 100.);
		unless ($new_size == $data->{_anaSize}) {
		    $data->{_anaSize} = $new_size;
		    $clock->_destroyAnalog;
		    $clock->_createAnalog;
		    if (exists $conf->{anaScale} && $data->{useDigital}) {
			# Otherwise the digital either overlaps the analog
			# or there is a gap
			$clock->_destroyDigital;
			$clock->_createDigital;
			}
		    $clock->after (5, ["_run" => $clock]);
		    }
		}
	    }
	elsif ($attr eq "backDrop" && $data->{useAnalog}) {
	    $clock->delete ("back");
	    if (ref $data->{backDrop} eq "Tk::Photo") {
		$clock->createImage (0, 0,
		    -anchor => "nw",
		    -image  => $data->{backDrop},
		    -tags   => "back",
		    );
		$clock->lower ("back", ($clock->find ("withtag", "tick"))[0]);
		}
	    }
	elsif ($attr eq "useAnalog") {
	    if    ($old == 1 && !$data->{useAnalog}) {
		$clock->_destroyAnalog;
		$clock->_destroyDigital;
		$data->{useDigital} and $clock->_createDigital;
		}
	    elsif ($old == 0 &&  $data->{useAnalog}) {
		$clock->_destroyDigital;
		$clock->_createAnalog;
		$data->{useDigital} and $clock->_createDigital;
		}
	    $clock->after (5, ["_run" => $clock]);
	    }
	elsif ($attr eq "useInfo") {
	    if ($old ^ $data->{useInfo} && $data->{useAnalog}) {
		$clock->_destroyAnalog;
		$clock->_destroyDigital;
		$clock->_createAnalog;
		$data->{useDigital} and $clock->_createDigital;
		}
	    $clock->after (5, ["_run" => $clock]);
	    }
	elsif ($attr eq "useDigital") {
	    if    ($old == 1 && !$data->{useDigital}) {
		$clock->_destroyDigital;
		}
	    elsif ($old == 0 &&  $data->{useDigital}) {
		$clock->_createDigital;
		}
	    $clock->after (5, ["_run" => $clock]);
	    }
	elsif ($attr eq "digiAlign") {
	    if ($data->{useDigital} && $old ne $data->{digiAlign}) {
		$clock->_destroyDigital;
		$clock->_createDigital;
		$clock->after (5, ["_run" => $clock]);
		}
	    }
	}
    _booleans ($data);
    if (defined $autoScale) {
	$data->{autoScale} = $autoScale;
	if ($autoScale) {
	    $clock->Tk::bind         ("Tk::Clock","<<ResizeRequest>>", \&_resize_auto);
	    $clock->parent->Tk::bind (            "<<ResizeRequest>>", \&_resize_auto);
	    $clock->_resize_auto;
	    }
	else {
	    $clock->Tk::bind         ("Tk::Clock","<<ResizeRequest>>", sub {});
	    $clock->parent->Tk::bind (            "<<ResizeRequest>>", sub {});
	    }
	}
    $clock->_resize;
    $clock;
    } # config

sub _run {
    my $clock = shift;

    my $data = $clock->privateData;

    $data->{timeZone} and local $ENV{TZ} = $data->{timeZone};
    my $t = time + $data->{localOffset};
    $t == $data->{_time_} and return;	# Same time, no update
    $t <  $data->{_time_} and		# Time wound back (ntp or date command)
	($data->{Clock_h}, $data->{Clock_m}, $data->{Clock_s}) = (-1, -1, -1);
    $data->{_time_} = $t;
    my @t = localtime $t;

    my ($Sc, $Mc, $Hc) = (0, 0, 0);
    if ($data->{timerValue}) {
	use integer;

	defined $data->{timerStart} or $data->{timerStart} = $t;
	my $tv = $data->{timerValue} - ($t - $data->{timerStart});
	if ($tv < 0) {
	    $data->{timerValue} = 0;
	    $data->{timerStart} = undef;
	    }
	else {
	    $Sc = $tv % 60;
	    $tv /= 60;
	    $Mc = $tv % 60;
	    $tv /= 60;
	    $Hc = $tv;
	    }
	}
    push @t, $Sc, $Mc, $Hc;

    unless ($t[2] == $data->{Clock_h}) {
	$data->{Clock_h} = $t[2];
	$data->{fmtd} ||= sub {
	    sprintf "%02d-%02d-%02d", $_[3], $_[4] + 1, $_[5] + 1900;
	    };
	$data->{useDigital} and
	    $clock->itemconfigure ("date", -text => $data->{fmtd}->(@t));
	}

    unless ($t[1] == $data->{Clock_m}) {
        $data->{Clock_m} = $t[1];
	if ($data->{useAnalog}) {
	    my ($h24, $m24) = $data->{ana24hour} ? (24, 2.5)  : (12, 5);
	    $clock->coords ("hour",
		$clock->_where (($data->{Clock_h} % $h24) * $m24 + $t[1] / $h24, 22, $data->{_anaSize}));

	    $clock->coords ("min",
		$clock->_where ($data->{Clock_m}, 30, $data->{_anaSize}));
	    }
	}

    $data->{Clock_s} = $t[0];
    if ($data->{useAnalog}) {
	$data->{useSecHand} and
	    $clock->coords ("sec",
		$clock->_where ($data->{Clock_s}, 34, $data->{_anaSize}));
	$data->{fmti} ||= sub { sprintf "%02d:%02d:%02d", @_[2,1,0]; };
	$data->{useInfo} and
	    $clock->itemconfigure ("info", -text => $data->{fmti}->(@t));
	}
    $data->{fmtt} ||= sub { sprintf "%02d:%02d:%02d", @_[2,1,0]; };
    $data->{useDigital} and
	$clock->itemconfigure ("time", -text => $data->{fmtt}->(@t));

    $data->{autoScale} and $clock->_resize_auto;
    } # _run

1;

__END__

=head1 NAME

Tk::Clock - Clock widget with analog and digital display

=head1 SYNOPSIS

  use Tk
  use Tk::Clock;

  $clock = $parent->Clock (?-option => <value> ...?);

  $clock->config (        # These reflect the defaults
      timeZone    => "",
      useLocale   => "C",
      backDrop    => "",

      useAnalog   => 1,
      handColor   => "Green4",
      secsColor   => "Green2",
      tickColor   => "Yellow4",
      tickFreq    => 1,
      tickDiff    => 0,
      useSecHand  => 1,
      handCenter  => 0,
      anaScale    => 100,
      autoScale   => 0,
      ana24hour   => 0,
      countDown   => 0,
      timerValue  => 0,
      localOffset => 0,

      useInfo     => 0,
      infoColor   => "#cfb53b",
      infoFormat  => "HH:MM:SS",
      infoFont    => "fixed 6",

      useDigital  => 1,
      digiAlign   => "center",
      timeFont    => "fixed 6",
      timeColor   => "Red4",
      timeFormat  => "HH:MM:SS",
      dateFont    => "fixed 6",
      dateColor   => "Blue4",
      dateFormat  => "dd-mm-yy",
      );

=head1 DESCRIPTION

This module implements a Canvas-based clock widget for perl-Tk with lots
of options to change the appearance.

Both analog and digital clocks are implemented.

=head1 METHODS

=head2 Clock

This is the constructor. It does accept the standard widget options plus those
described in L</config>.

=head2 config

Below is a description of the options/attributes currently available. Their
default value is in between parenthesis.

=over 4

=item useAnalog (1)

=item useInfo (0)

=item useDigital (1)

Enable the analog clock (C<useAnalog>) and/or the digital clock (C<useDigital>)
in the widget. The analog clock will always be displayed above the digital part

  +----------+
  |    ..    |  \
  |  . \_ .  |   |_ Analog clock
  |  .    .  |   |
  |    ..    |  /
  | 23:59:59 |  --- Digital time
  | 31-12-09 |  --- Digital date
  +----------+

The analog clock displays ticks, hour hand, minutes hand and second hand.
The digital part displays two parts, which are configurable. By default
these are time and date.

The C<useInfo> enables a text field between the backdrop of the analog
clock and its items. You can use this field to display personal data.

=item autoScale (0)

When set to a true value, the widget will try to re-scale itself to
automatically fit the containing widget.

  $clock->config (autoScale => 1);

=item anaScale (100)

The analog clock can be enlarged or reduced using anaScale for which
the default of 100% is about 72x72 pixels.

When using C<pack> for your geometry management, be sure to pass
C<-expand =&gt; 1, -fill =&gt; "both"> if you plan to resize with
C<anaScale> or enable/disable either analog or digital after the
clock was displayed.

  $clock->config (anaScale => 400);

=item ana24hour (0)

The default for the analog clock it the normal 12 hours display, as
most clocks are. This option will show a clock where one round of the
hour-hand will cover a full day of 24 hours, noon is at the bottom
where the 6 will normally display.

  $clock->config (ana24hour => 1);

=item useSecHand (1)

This controls weather the seconds-hand is shown.

  $clock->config (useSecHand => 0);

=item countDown (0)

When C<countDown> is set to a true value, the clock will run backwards.
This is a slightly experimental feature, it will not count down to a
specific point in time, but will simply reverse the rotation, making
the analog clock run counterclockwise.

=item timerValue (0)

This represents a countdown timer.

When setting C<timerValue> to a number of seconds, the format values
C<Hc>, C<Mc>, and C<Sc> will represent the hour, minute and second of
the this value. When the time reaches 0, all countdown values are
reset to 0.

=item localOffset (0)

The value of this attribute represents the local offset for this clock
in seconds. Negative is back in time, positive is in the future.

  # Wind back clock 4 days, 5 hours, 6 minutes and 7 seconds
  $clock->config (localOffset => -363967);

=item handColor ("Green4")

=item secsColor ("Green2")

Set the color of the hands of the analog clock. C<handColor> controls
the color for both the hour-hand and the minute-hand. C<secsColor>
controls the color for the seconds-hand.

  $clock->config (
      handColor => "#7F0000",
      secsColor => "OrangeRed",
      );

=item handCenter (0)

If set to a true value, will display a circular extension in the center
of the analog clock that extends the hands as if they have a wider area
at their turning point, like many station-type clocks (at least in the
Netherlands) have.

  $clock->config (handCenter => 1);

=item tickColor ("Yellow4")

Controls the color of the ticks in the analog clock.

  $clock->config (tickColor => "White");

=item tickFreq (1)

=item tickDiff (0)

C<tickFreq> controls how many ticks are shown in the analog clock.

Meaningful values for C<tickFreq> are 1, 5 and 15 showing all ticks, tick
every 5 minutes or the four main ticks only, though any positive integer
will do (put a tick on any C<tickFreq> minute).

When setting tickDiff to a true value, the major ticks will use a thicker
line than the minor ticks.

  $clock->config (
      tickFreq => 5,
      tickDiff => 1,
      );

=item timeZone ("")

Set the timezone for the widget. The format should be the format recognized
by the system. If unset, the local timezone is used.

  $clock->config (timeZone => "Europe/Amsterdam");
  $clock->config (timeZone => "MET-1METDST");

=item useLocale ("C")

Use this locale for the text shown in month formats C<mmm> and C<mmmm> and in
day formats C<ddd> and C<dddd>.

  $clock->config (useLocale => $ENV{LC_TIME} // $ENV{LC_ALL}
                            // $ENV{LANG}    // "nl_NL.utf8");

See L<http://docs.moodle.org/dev/Table_of_locales> for a table of locales
and the Windows equivalents. Windows might not have a UTF8 version available
of the required locale.

=item timeFont ("fixed 6")

Controls the font to be used for the top line in the digital clock. Will
accept all fonts that are supported in your version of perl/Tk. This includes
both True Type and X11 notation.

  $clock->config (timeFont => "{Liberation Mono} 11");

=item timeColor ("Red4")

Controls the color of the first line (time) of the digital clock.

  $clock->config (timeColor => "#00ff00");

=item timeFormat ("HH:MM:SS")

Defines the format of the first line of the digital clock. By default it
will display the time in a 24-hour notation.

Legal C<timeFormat> characters are C<H> and C<HH> for 24-hour, C<h> and
C<hh> for AM/PM hour, C<M> and C<MM> for minutes, C<S> and C<SS> for
seconds, C<Hc> for countdown/timer hour, C<Mc> for countdown/timer
minutes, C<Sc> for countdown/timer seconds, C<A> for AM/PM indicator,
C<d> and C<dd> for day-of-the month, C<ddd> and C<dddd> for short and
long weekday, C<m>, C<mm>, C<mmm> and C<mmmm> for month, C<y> and C<yy>
for year, C<w> and C<ww> for week-number and any separators C<:>, C<->,
C</> or C<space>.

  $clock->config (timeFormat => "hh:MM A");

The text shown in the formats C<ddd>, C<dddd>, C<mmm>, and C<mmmm> might be
influenced by the setting of C<useLocale>. The fallback is locale "C".

=item dateFont ("fixed 6")

Controls the font to be used for the bottom line in the digital clock. Will
accept all fonts that are supported in your version of perl/Tk. This includes
both True Type and X11 notation.

  $clock->config (dateFont => "-misc-fixed-*-normal--15-*-c-iso8859-1");

=item dateColor ("Blue4")

Controls the color of the second line (date) of the digital clock.

  $clock->config (dateColor => "Navy");

=item dateFormat ("dd-mm-yy")

Defines the format of the second line of the digital clock. By default it
will display the date in three groups of two digits representing the day of
the month, the month, and the last two digits of the year, separated by dashes.

  $clock->config (dateFormat => "ww dd-mm");

The supported format is the same as for C<timeFormat>.

=item infoFont ("fixed 6")

Controls the font to be used for the info label in the analog clock. Will
accept all fonts that are supported in your version of perl/Tk. This includes
both True Type and X11 notation.

  $clock->config (infoFont => "{DejaVu Sans Mono} 8");

=item infoColor ("#cfb53b")

Controls the color of the info label of the analog clock (default is a
shade of Gold).

  $clock->config (infoColor => "Yellow");

=item infoFormat ("HH:MM:SS")

Defines the format of the label inside the analog clock. By default will not
be displayed. Just as C<timeFormat> and C<dateFormat> the content is updated
every second if enabled.

  $clock->config (infoFormat => "BREITLING");

The supported format is the same as for C<timeFormat>.

=item digiAlign ("center")

Controls the placement of the text in the digital clock. The only legal values
for C<digiAlign> are "left", "center", and "right".
Any other value will be interpreted as the default "center".

  $clock->config (digiAlign => "right");

=item backDrop ("")

By default the background of the clock is controlled by the C<-background>
attribute to the constructor, which may default to the default background
used in the perl/Tk script.

The C<backDrop> attribute accepts any valid Tk::Photo object, and it will
show (part of) the image as a backdrop of the clock

  use Tk;
  use Tk::Clock;
  use Tk::Photo;
  use Tk::PNG;

  my $mainw = MainWindow->new;
  my $backd = $mainw->Photo (
      -file    => "image.png",
      );
  my $clock = $mainw->Clock (
      -relief  => "flat",
      )->pack (-expand => 1, -fill => "both");
  $clock->config (
      backDrop => $backd,
      );
  MainLoop;

=back

The C<new ()> constructor will also accept options valid for Canvas widgets,
like C<-background> and C<-relief>.

=head1 TAGS

As all of the clock is part of a Canvas, the items cannot be addressed as
Subwidgets. You can however alter presentation afterwards using the tags:

 my $clock = $mw->Clock->pack;
 $clock->itemconfigure ("date", -fill => "Red");

Currently defined tags are C<date>, C<hour>, C<info>, C<min>, C<sec>,
C<tick>, and C<time>.

=head1 BUGS

If the system load's too high, the clock might skip some seconds.

There's no check if either format will fit in the given space.

=head1 TODO

* Full support for multi-line date- and time-formats with auto-resize.
* Countdown clock API, incl action when done.
* Better docs for the attributes

=head1 SEE ALSO

Tk(3), Tk::Canvas(3), Tk::Widget(3), Tk::Derived(3)

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

Thanks to Larry Wall for inventing perl.
Thanks to Nick Ing-Simmons for providing perlTk.
Thanks to Achim Bohnet for introducing me to OO (and converting
    the basics of my clock.pl to Tk::Clock.pm).
Thanks to Sriram Srinivasan for understanding OO though his Panther book.
Thanks to all CPAN providers for support of different modules to learn from.
Thanks to all who have given me feedback and weird ideas.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1999-2020 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
