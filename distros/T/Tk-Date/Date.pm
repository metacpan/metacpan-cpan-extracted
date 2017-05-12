# -*- perl -*-

#
# $Id: Date.pm,v 1.71 2010/10/25 20:10:31 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997, 1998, 1999, 2000, 2001, 2005, 2007, 2008, 2010 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.sourceforge.net/projects/srezic
#

package Tk::Date;
use Time::Local qw(timelocal);
use strict;
use vars qw($VERSION @ISA $DEBUG $has_numentryplain $has_numentry
	    @monlen %choice $en_weekdays $en_monthnames
	    $weekdays $monthnames
	   );
use Tk::Frame;
@ISA = qw(Tk::Frame);
Construct Tk::Widget 'Date';

$VERSION = '0.44';
$VERSION = eval $VERSION;

@monlen = (undef, 31, undef, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
 # XXX DST?
%choice =
  ('today'              => ['Today',     sub { time() }],
   'now'                => ['Now',       sub { time() }],
   'yesterday'          => ['Yesterday', sub { time()-86400 } ],
   'tomorrow'           => ['Tomorrow',  sub { time()+86400 } ],

   'today_midnight'     => ['Today',     sub { _begin_of_day(time()) }],
   'yesterday_midnight' => ['Yesterday', sub { _begin_of_day(time()-86400) } ],
   'tomorrow_midnight'  => ['Tomorrow',  sub { _begin_of_day(time()+86400) } ],

   'beginning_of_month' => ['Beginning of month' =>
			    sub { my(@l) = localtime;
				  $l[3] = 1;
				  _begin_of_day(timelocal(@l));
			      }],
   'end_of_month'       => ['End of month' =>
			    sub { my(@l) = localtime;
				  foreach (31, 30, 29, 28) {
				      $l[3] = $_;
				      my $t = timelocal(@l);
				      my(@l2) = localtime $t;
				      return _end_of_day($t)
					  if ($l[4] == $l2[4]);
				  }
				  die "Can't get end of month";
			      }],

   'reset'              => ['Reset',     'RESET'],
  );

$has_numentryplain = 0;
$has_numentry      = 0;

$en_weekdays = [qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)];
$en_monthnames = [qw(January February March April May June
		     July August September October November December)];

######################################################################
package Tk::Date::NumEntryPlain;
use vars qw(@ISA);
eval {
    require Tk::NumEntryPlain;
    @ISA = qw(Tk::NumEntryPlain);
    Construct Tk::Widget 'DateNumEntryPlain';

    sub Populate {
	my($w, $args) = @_;
	$w->SUPER::Populate($args);
	$w->ConfigSpecs
	    (-frameparent    => [qw/PASSIVE/],
	     -numentryparent => [qw/PASSIVE/, undef, undef, $w],
	     -field          => [qw/PASSIVE/],
	    );
    }
    sub value { }
    sub incdec {
	my($e, $inc) = @_;
	my $val = $e->get;
	# XXX $inc == 0 -> range check
	if (defined $inc and $inc != 0) {
	    my $fw = $e->cget(-frameparent);
	    my $date_w = $fw->parent;
	    $date_w->firebutton_command($fw, $inc, $e->cget(-field));
	}
    }

    $Tk::Date::has_numentryplain++;
};

######################################################################
package Tk::Date::NumEntry;
use vars qw(@ISA);
eval {
    require Tk::NumEntryPlain;
    require Tk::NumEntry;
    Tk::NumEntry->VERSION(1.08);
    @ISA = qw(Tk::NumEntry);
    Construct Tk::Widget 'DateNumEntry';

    sub NumEntryPlainWidget { "DateNumEntryPlain" }

    sub Populate {
	my($w, $args) = @_;
	$w->SUPER::Populate($args);
	$w->Subwidget("entry")->configure
	    (-frameparent    => delete $args->{'frameparent'},
	     -numentryparent => $w);
    }

    $Tk::Date::has_numentry++;
};

######################################################################

package Tk::Date;

sub MonthOptionmenu {
    require Tk::Optionmenu;
    "Optionmenu";
}

sub Populate {
    my($w, $args) = @_;
    $w->SUPER::Populate($args);

    my $has_firebutton = 0;
    eval {
	require Tk::FireButton;
	$has_firebutton = 1;
    };

    # and now the construction-time options

    # -editable
    my $editable = 1;
    if (exists $args->{-editable}) { $editable  = delete $args->{-editable} }

    # -fields
    my $fields = 'both';
    if (exists $args->{-fields})   { $fields = delete $args->{-fields} }
    if ($fields !~ /^(date|time|both)$/) {
	die "Invalid option for -fields: must be date, time or both";
    }

    # -choices
    my $choices        = delete $args->{-choices};
    if ($choices) {
	if (ref $choices ne 'ARRAY') {
	    $choices = [$choices];
	}
    } else {
	$choices = [];
    }

    # -allarrows
    my $allarrows      = delete $args->{-allarrows};
    if (!$has_numentry and $allarrows) {
	warn "-allarrows needs Tk::NumEntry => disabled"
	    if $^W;
	$allarrows = 0;
    }

    # -monthmenu
    $w->{Configure}{-monthmenu} = delete $args->{-monthmenu};

    # -from and -to (not yet implemented)
    my $from           = delete $args->{-from}; # XXX TODO
    my $to             = delete $args->{-to};   # XXX TODO

    # -varfmt
    $w->{Configure}{-varfmt}  = delete $args->{-varfmt} || 'unixtime';

    # -orient
    my $orient         = delete $args->{-orient} || 'v';
    if ($orient !~ /^(v|h)/) {
	die "Invalid option for -orient: must be horizontal or vertical";
    } else {
	$orient = $1;
    }

    # -selectlabel
    $w->{Configure}{-selectlabel} = delete $args->{-selectlabel} || 'Select:';

    # -check
    my $check          = delete $args->{-check};

    # -weekdays
    $w->{Configure}{-weekdays} = delete $args->{-weekdays}
                                 || $w->_get_week_days;

    die "-weekdays argument should be a reference to a 7-element array"
	if (!ref $w->{Configure}{-weekdays} eq 'ARRAY' and
	    scalar $w->{Configure}{-weekdays} != 7);

    # -monthnames
    $w->{Configure}{-monthnames} = delete $args->{-monthnames}
                                   || $w->_get_month_names;
    die "-monthnames argument should be a reference to a 12-element array"
	if (!ref $w->{Configure}{-monthnames} eq 'ARRAY' and
	    scalar $w->{Configure}{-monthnames} != 12);

    # -readonly
    my $readonly = delete $args->{-readonly};

    $w->{IncFireButtons} = [];
    $w->{DecFireButtons} = [];
    $w->{NumEntries}     = [];

    my $DateEntry;
    my @DateEntryArgs;
    if ($allarrows) {
	$DateEntry = "DateNumEntry";
	if ($readonly && $Tk::NumEntry::VERSION >= 2.03) {
	    push @DateEntryArgs, -readonly => 1;
	}
    } elsif ($has_numentryplain) {
	$DateEntry = "DateNumEntryPlain";
    }

    # Construction of Date field
    if ($fields ne 'time') {
	my %range = ('d' => [1, 31],
		     'm' => [1, 12],
		    );
	my $dw = $w->Frame->pack(-side => 'left');
	$w->Advertise(dateframe => $dw);
	my @datefmt = _fmt_to_array(delete $args->{-datefmt} || "%2d.%2m.%4y");

	foreach (@datefmt) {
	    if ($_ =~ /^%(\d+)?(.)$/) {
		my($l, $k) = ($1, $2);
		if (!$editable || $k eq 'A') {  # A = weekday
		    $w->{Sub}{$k} =
		      $dw->Label(($l ? (-width => $l) : ()),
				 -borderwidth => 0,
				)->pack(-side => 'left');
		} else {
		    $w->{Var}{$k} = undef;
		    my $dne;
		    if ($k eq 'm' and $w->{Configure}{-monthmenu}) {
			my $month_i = 1;
			my $dummy; # this is only for Tk's < 800.023
			my $Optionmenu = $w->MonthOptionmenu;
			$dne = $dw->$Optionmenu
			    (-variable => \$w->{Var}{$k},
			     -textvariable => \$dummy,
			     ($check
			      ? (-command => sub { $w->inc_date($dw,0) })
                              : ()
                             ),
			    );
			$dne->addOptions(map { [$_ => $month_i++ ] }
					 @{ $w->{Configure}{-monthnames} });
		    } else {
			my $e_dne;
			if ($has_numentryplain || $has_numentry) {
			    $dne =
				$dw->$DateEntry
				    (-width => $l,
				     (exists $range{$k} ?
				      ((defined $range{$k}->[0]
					? (-minvalue => $range{$k}->[0]) : ()),
				       (defined $range{$k}->[1]
					? (-maxvalue => $range{$k}->[1]) : ()),
				      ) : ()),
				     # XXX NumEntryPlain ist buggy
				     -textvariable => \$w->{Var}{$k},
				     -frameparent => $dw,
				     -field => $k,
				     @DateEntryArgs,
				    );
			    $e_dne = $dne->Subwidget("entry") || $dne;
			} else {
			    $e_dne = $dne =
				$dw->Entry(-width => $l,
					   -textvariable => \$w->{Var}{$k});
			}
		    }

		    $w->{Sub}{$k} = $dne;
		    $dne->pack(-side => 'left');
		    if ($check) {
			$dne->bind('<FocusOut>' =>
				   sub { $w->inc_date($dw, 0)});
		    }
		    push @{$w->{NumEntries}}, $dne;
		}
		push(@{$dw->{Sub}}, $k);
		$w->{'len'}{$k} = $l;
	    } else {
		$dw->Label(-text => $_,
			   -borderwidth => 0,
			  )->pack(-side => 'left');
	    }
	}

	if ($editable && $has_firebutton && !$allarrows) {
	    my $f = $dw->Frame->pack(-side => 'left');
	    my($fb1, $fb2);
	    if ($orient eq 'h') {
		$fb2 = $f->FireButton
		  (-command => sub { $w->firebutton_command($dw, -1, 'date') },
		  )->pack(-side => 'left');
		$fb1 = $f->FireButton
		  (-command => sub { $w->firebutton_command($dw, +1, 'date') },
		  )->pack(-side => 'left');
	    } else {
		$fb1 = $f->FireButton
		  (-command => sub { $w->firebutton_command($dw, +1, 'date') },
		  )->pack;
		$fb2 = $f->FireButton
		  (-command => sub { $w->firebutton_command($dw, -1, 'date') },
		  )->pack;
	    }
	    push(@{$w->{IncFireButtons}}, $fb1);
	    push(@{$w->{DecFireButtons}}, $fb2);
	}
    }

    # spacer between Date and Time field
    if ($fields eq 'both') {
	$w->Label->pack(-side => 'left');
    }

    # Construction of Time field
    if ($fields ne 'date') {
	my %range = ('H' => [0, 23],
		     'M' => [0, 59],
		     'S' => [0, 59],
		    );
	my $tw = $w->Frame->pack(-side => 'left');
	$w->Advertise(timeframe => $tw);
	my @timefmt = _fmt_to_array(delete $args->{-timefmt} || "%2H:%2M:%2S");
	foreach (@timefmt) {
	    if ($_ =~ /^%(\d)?(.)$/) {
		my($l, $k) = ($1, $2);
		if (!$editable) {
		    $w->{Sub}{$k} =
		      $tw->Label(-width => $l,
				 -borderwidth => 0,
				)->pack(-side => 'left');
		} else {
		    $w->{Var}{$k} = undef;
		    my $dne;
		    if ($has_numentryplain || $has_numentry) {
			$dne = $tw->$DateEntry
			  (-width => $l,
			   (exists $range{$k} ?
			    ((defined $range{$k}->[0]
			      ? (-minvalue => $range{$k}->[0]) : ()),
			     (defined $range{$k}->[1]
			      ? (-maxvalue => $range{$k}->[1]) : ()),
			    ) : ()),
			   -textvariable => \$w->{Var}{$k},
			   -frameparent => $tw,
			   -field => $k,
			   @DateEntryArgs,
			  );
		    } else {
			$dne = $tw->Entry(-width => $l,
					  -textvariable => \$w->{Var}{$k});
		    }
		    $w->{Sub}{$k} = $dne;
		    $dne->pack(-side => 'left');
		    if ($check) {
			$dne->bind('<FocusOut>' =>
				   sub { $w->inc_date($tw, 0)});
		    }
		    push @{$w->{NumEntries}}, $dne;
		}
		push @{$tw->{Sub}}, $k;
		$w->{'len'}{$k} = $l;
	    } else {
		$tw->Label(-text => $_,
			   -borderwidth => 0,
			  )->pack(-side => 'left');
	    }
	}
	if ($editable && $has_firebutton && !$allarrows) {
	    my $f = $tw->Frame->pack(-side => 'left');
	    my($fb1, $fb2);
	    if ($orient eq 'h') {
		$fb2 = $f->FireButton
		  (-command => sub { $w->firebutton_command($tw, -1, 'time') },
		  )->pack(-side => 'left');
		$fb1 = $f->FireButton
		  (-command => sub { $w->firebutton_command($tw, +1, 'time') },
		  )->pack(-side => 'left');
	    } else {
		$fb1 = $f->FireButton
		  (-command => sub { $w->firebutton_command($tw, +1, 'time') },
		  )->pack;
		$fb2 = $f->FireButton
		  (-command => sub { $w->firebutton_command($tw, -1, 'time') },
		  )->pack;
	    }
	    push(@{$w->{IncFireButtons}}, $fb1);
	    push(@{$w->{DecFireButtons}}, $fb2);
	}

    }

    # Construction of choices optionmenu button for fixed dates
    if (@$choices) {
	my($b, $b_menu, $b_sub);
	my %text2time;
	if (@$choices > 1) {
	    require Tk::Menubutton;
	    $b = $w->Menubutton(-relief => 'raised',
				-borderwidth => 2,
				-takefocus => 1,
				-highlightthickness => 2,
				-text => $w->{Configure}{-selectlabel},
			       );
	    $w->Advertise('chooser' => $b);
	    $b_menu = $b->Menu;
	    $b->configure(-menu => $b_menu);
	    $b_sub = sub {
		my $time = $text2time{$_[0]};
		if (ref $time eq 'CODE') {
		    $w->set_localtime(&$time);
		} elsif ($time eq 'RESET') {
		    $w->reset;
		} else {
		    $w->set_localtime($time);
		}
		if ($w->{Configure}{-command}) {
		    $w->Callback(-command => $w);
		}
	    };
	} else {
	    $b = $w->Button;
	    $w->Advertise('chooserbutton' => $b);
	}
	$b->pack(-side => 'left');
	foreach (@$choices) {
	    my($text, $time);
	    if (ref $_ eq 'ARRAY') {
		$text = $_->[0];
		$time = $_->[1];
	    } elsif (exists $choice{$_}) {
		$text = $choice{$_}->[0];
		$time = $choice{$_}->[1];

	    } else {
		die "Unknown choice: $_";
	    }
	    $text2time{$text} = $time;

	    if (@$choices > 1) {
		$b_menu->command(-label => $text,
				 -command => sub { &$b_sub($text) },
				);
	    } else {
		$b->configure(-text => $text,
			      -command => sub {
				  if (ref $time eq 'CODE') {
				      $w->set_localtime(&$time);
				  } elsif ($time eq 'RESET') {
				      $w->reset;
				  } else {
				      $w->set_localtime($time);
				  }
				  if ($w->{Configure}{-command}) {
				      $w->Callback(-command => $w);
				  }
			      });
	    }
	}
    }

    # Default values for firebutton images.
    # Distinguish between horizontal and vertical images.
    my($incbitmap, $decbitmap);
    if ($orient eq 'v') {
	($incbitmap, $decbitmap) = ($Tk::FireButton::INCBITMAP,
				    $Tk::FireButton::DECBITMAP);
    } else {
	($incbitmap, $decbitmap) = ($Tk::FireButton::HORIZINCBITMAP,
				    $Tk::FireButton::HORIZDECBITMAP);
    }

    $w->ConfigSpecs
      (-repeatinterval => ['METHOD', 'repeatInterval', 'RepeatInterval', 50],
       -repeatdelay    => ['METHOD', 'repeatDelay',    'RepeatDelay',   500],
       -decbitmap      => ['METHOD',      'decBitmap',  'DecBitmap',
			   $decbitmap],
       -incbitmap      => ['METHOD',      'incBitmap',  'IncBitmap',
			   $incbitmap],
       -bell           => ['METHOD', 'bell', 'Bell', undef],
       -background     => ['DESCENDANTS', 'background', 'Background', undef],
       -foreground     => ['DESCENDANTS', 'foreground', 'Foreground', undef],
       -precommand     => ['CALLBACK',    'preCommand', 'PreCommand', undef],
       -command        => ['CALLBACK',    'command',    'Command',    undef],
       -variable       => ['METHOD',      'variable',   'Variable',   undef],
       -value          => ['METHOD',      'value',      'Value',      undef],
       -innerbg        => ['SETMETHOD',   'innerBg', 'InnerBg',    undef],
       -innerfg        => ['SETMETHOD',   'innerFg', 'InnerFg',    undef],
       -state          => ['METHOD',      'state',   'State',      'normal'],
      );

    $w;
}

sub value {
    my($w, $value) = @_;
    my $varfmt = $w->{Configure}{-varfmt};
    if ($value eq 'now') {
	$w->set_localtime($value);
    } elsif ($varfmt eq 'unixtime') {
	my $varref;
	tie $varref, 'Tk::Date::UnixTime', $w, $value;
	untie $varref;
    } elsif ($varfmt eq 'datehash') {
	my %varref;
	tie %varref, 'Tk::Date::DateHash', $w, $value;
	untie %varref;
    } else {
	die;
    }
}

sub decbitmap {
    my $w = shift;
    eval {
	local $SIG{__DIE__};
	$w->subwconfigure($w->{DecFireButtons}, '-bitmap', @_);
    };
}
sub incbitmap {
    my $w = shift;
    eval {
	local $SIG{__DIE__};
	$w->subwconfigure($w->{IncFireButtons}, '-bitmap', @_);
    };
}
sub repeatinterval {
    my $w = shift;
    eval {
	local $SIG{__DIE__};
	$w->subwconfigure([@{$w->{DecFireButtons}}, @{$w->{IncFireButtons}}],
			  '-repeatinterval', @_);
    };
}
sub repeatdelay {
    my $w = shift;
    eval {
	local $SIG{__DIE__};
	$w->subwconfigure([@{$w->{DecFireButtons}}, @{$w->{IncFireButtons}}],
			  '-repeatdelay', @_);
    };
}
sub bell {
    my $w = shift;
    eval {
	local $SIG{__DIE__};
	$w->subwconfigure($w->{NumEntries}, '-bell', @_);
    };
}

sub innerfg {
    my($w, $key, $val) = @_;
    $w->subwconfigure($w->{NumEntries}, '-fg', $val);
}

sub innerbg {
    my($w, $key, $val) = @_;
    $w->subwconfigure($w->{NumEntries}, '-bg', $val);
}

sub state {
    my($w, $state) = @_;
    if (@_ > 1) {
	die "Invalid state $state" if $state !~ /^(normal|disabled)$/;
	foreach my $ww (values %{ $w->{Sub} }) {
	    eval '$ww->configure("-state" => $state);';
	    #warn "$ww: $@" if $@;
	}
	my $chooser = $w->Subwidget("chooser");
	if (Tk::Exists($chooser)) {
	    $chooser->configure(-state => $state);
	}
	$w->{Configure}{"-state"} = $state;
    } else {
	$w->{Configure}{"-state"};
    }
}

sub subwconfigure {
    my($w, $subw, $key, $val) = @_;
    my @w = @$subw;
    if (@_ > 3) {
	foreach (@w) {
	    $_->configure($key => $val);
	}
    } else {
	if (@w) {
	    $w[0]->cget($key);
	} else {
	    undef;
	}
    }
}

sub variable {
    my($w, $varref) = @_;
    if (@_ > 1 and defined $varref) {
	my $varfmt = $w->{Configure}{-varfmt};
	if ($varfmt eq 'unixtime') {
	    my $savevar = $$varref;
	    tie $$varref, 'Tk::Date::UnixTime', $w, $savevar;
	} elsif ($varfmt eq 'datehash') {
	    my(%savevar) = %$varref;
	    tie %$varref, 'Tk::Date::DateHash', $w, \%savevar;
	} else {
	    tie $$varref, $varfmt, $w, $$varref;
	}
	$w->{Configure}{-variable} = $varref;
#	$w->OnDestroy(sub { $w->DESTROY });
    } else {
	$w->{Configure}{-variable};
    }
}

# should be eliminated or renamed ... only "now" is still needed
sub set_localtime {
    my($w, $setdate) = @_;
    if (defined $setdate and $setdate eq 'now') {
	$setdate = time();
    }
    if (!defined $setdate or ref $setdate ne 'HASH') {
	my @t;
	if (defined $setdate) {
	    @t = localtime $setdate;
	} else {
	    @t = localtime;
	}
	$setdate = { 'S' => $t[0],
		     'M' => $t[1],
		     'H' => $t[2],
		     'd' => $t[3],
		     'm' => $t[4]+1,
		     'y' => $t[5]+1900,
		     'A' => $t[6]
		   };
    }

    foreach (qw(y m d H M S)) { # umgekehrte Reihenfolge!
	if (defined $setdate->{$_}) {
	    $w->set_date($_, $setdate->{$_});
	}
    }
}

sub reset {
    my $w = shift;
    foreach my $key (qw(A y m d H M S)) {
	my $sw = $w->{Sub}{$key};
	if (Tk::Exists($sw)) {
	    if ($key eq 'A' || $sw->isa('Tk::Label')) {
		$sw->configure(-text => '');
	    } elsif ($sw->isa('Tk::Optionmenu')) {
		# XXX hackish!
		$ {$sw->cget('-variable')} = 1;
		$ {$sw->cget('-textvariable')} = $w->{Configure}{-monthnames}->[0];
	    } else {
		$sw->delete(0, 'end');
		$sw->insert(0, '');
	    }
	}
    }
}

sub get {
    my($w, $fmt) = @_;
    $fmt = '%s' if !defined $fmt;
    my %date;
    foreach (qw(y m d H M S)) {
	$date{$_} = $w->get_date($_, 1);
	if ($date{$_} eq '') { $date{$_} = 0 }
    }
    $date{'m'}--;
    $date{'y'}-=1900;
# XXX weekday should also be set
    # -1: let strftime/mktime divine whether summer time is in effect
    if ($fmt eq '%s') {
	# %s is an (BSD?) extension to strftime and not part of POSIX. Use
	# timelocal (this is the perl mktime) instead.
        my $ret;
	$ret = eval {
	    local $SIG{'__DIE__'};
	    timelocal(@date{qw(S M H d m y)});
	};
	return $ret;
    } else {
	my $ret;
	my $errors = "";
	$ret = eval {
	    require POSIX;
	    POSIX::strftime($fmt, @date{qw(S M H d m y)}, 0, 0, -1);
	};
	return $ret if (!$@);
	$errors .= $@;
	$ret = eval {
	    require Date::Format;
	    Date::Format::strftime($fmt, [@date{qw(S M H d m y)}, 0, 0, -1]);
	};
	return $ret if (!$@);
	$errors .= $@;
	die "Can't access strftime function." .
	  "You have to install either the POSIX or Date::Format module.\n" .
	  "Detailed errors:\n$errors";
    }
}

# Get the date/time value for key $key (S,M,H,d,m,y)
# If $defined is set to true, always get a defined value, i.e. return
# the current time if the key is not set in the widget.
sub get_date {
    my($w, $key, $defined) = @_;
    my $sw = $w->{Sub}{$key};
    if (Tk::Exists($sw)) {
	if ($sw->isa('Tk::Entry') ||
	    $sw->isa('Tk::NumEntry')) {
	    my $r;
	    if (ref $w->{Var}{$key} eq 'SCALAR') {
		$r = $ {$w->{Var}{$key}}; # XXX NumEntryPlain ist buggy
	    } else {
		$r = $sw->get;
	    }
	    if (!defined $r or $r eq '' && $defined) {
		$r = _now($key);
	    }
	    $r;
	} elsif ($sw->isa('Tk::Optionmenu')) {
	    # XXX hackish!
	    $ {$sw->cget('-variable')};
	} elsif ($sw->isa('Tk::Label')) {
	    $sw->cget(-text);
	}
    } elsif ($defined) {
	_now($key);
    }
}

sub set_date {
    my($w, $key, $value, %args) = @_;
    $value = 0 if !defined $value; # XXX ???

    if ($key eq 'd') {
	if (!$args{-correcting}) {
	    if ($value < 1) {
		my $m = $w->set_date('m', $w->get_date('m', 1)-1);
		$value = _monlen($m, $w->get_date('y', 1));
	    } else {
		my $m = $w->get_date('m', 1);
		if (defined $m and $m ne '') {
		    my $y = $w->get_date('y', 1);
		    if (defined $y and $y ne '' and $value > _monlen($m, $y)) {
			$value = 1;
			$w->set_date('m', $m+1);
		    }
		}
	    }
	}
    } elsif ($key eq 'm') {
	if ($value < 1) {
	    $value = 12;
	    $w->set_date('y', $w->get_date('y', 1)-1);
	} elsif ($value > 12) {
	    $value = 1;
	    $w->set_date('y', $w->get_date('y', 1)+1);
	}
	# maybe correct day
	my $d = $w->get_date('d', 1);
	if (defined $d && $d ne '') {
	    my $max_d = _monlen($value, $w->get_date('y', 1));
	    if ($d > $max_d) {
		$w->set_date('d', $max_d, -correcting => 1);
  	    }
	}
    } elsif ($key eq 'H') {
	if ($value < 0) {
	    $value = 23;
	    $w->set_date('d', $w->get_date('d', 1)-1);
	} elsif ($value > 23) {
	    $value = 0;
	    $w->set_date('d', $w->get_date('d', 1)+1);
	}
    } elsif ($key eq 'y') {
	# maybe correct day for leap years
	my $d = $w->get_date('d', 1);
	if (defined $d and $d ne '') {
	    my $max_d = _monlen($w->get_date('m', 1), $value);
	    if ($d > $max_d) {
		$w->set_date('d', $max_d);
 	    }
	}
    } elsif ($key eq 'M') {
	if ($value < 0) {
	    $value = 59;
	    $w->set_date('H', $w->get_date('H', 1)-1);
	} elsif ($value > 59) {
	    $value = 0;
	    $w->set_date('H', $w->get_date('H', 1)+1);
	}
    } elsif ($key eq 'S') {
	if ($value < 0) {
	    $value = 59;
	    $w->set_date('M', $w->get_date('M', 1)-1);
	} elsif ($value > 59) {
	    $value = 0;
	    $w->set_date('M', $w->get_date('M', 1)+1);
	}
    }

    my $sw = $w->{Sub}{$key};
    if (Tk::Exists($sw)) {
	if ($key eq 'A') {
	    $sw->configure(-text => $value);
	} else {
	    my $v = sprintf("%0".($w->{'len'}{$key}||"")."d", $value);
	    if ($sw->isa('Tk::Entry') ||
		$sw->isa('Tk::NumEntry')) {
		$sw->delete(0, 'end');
		$sw->insert(0, $v);
	    } elsif ($sw->isa('Tk::Optionmenu')) {
		# XXX hackish!
		$ {$sw->cget('-variable')} = $v;
		$ {$sw->cget('-textvariable')} = $w->{Configure}{-monthnames}->[$v-1];
	    } elsif ($sw->isa('Tk::Label')) {
		$sw->configure(-text => $v);
	    }
	}
    }

    if ($key =~ /^[dmy]$/) {
	my $d = $w->get_date('d', 1);
	my $m = $w->get_date('m', 1);
	my $y = $w->get_date('y', 1);
	if ($d ne '' and $m ne '' and $y ne '') {
	    my $t;
	    eval {
		$t = timelocal(0,0,0, $d, $m-1, $y-1900);
	    };
	    if (!$@ and defined $t) {
		$w->set_date('A', $w->{Configure}{-weekdays}->[(localtime($t))[6]]);
	    }
	}
    }

    $value;
}

sub _monlen {
    my($mon, $year) = @_;
    if ($mon != 2) {
	$monlen[$mon];
    } elsif ($year % 4 == 0 &&
	     (($year % 100 != 0) || ($year % 400 == 0))) {
	29;
    } else {
	28;
    }
}

sub _get_week_days {
    return $weekdays if $weekdays;
    eval {
	my $loc = _get_datetime_locale();
	my @weekdays = @{ $loc->can('day_format_wide') ? $loc->day_format_wide : $loc->day_names }; # clone!
	unshift @weekdays, pop @weekdays;
	$weekdays = \@weekdays;
    };
    return $weekdays if $weekdays;
    warn $@ if $@ && $DEBUG;
    eval {
	require POSIX;
	POSIX->VERSION(1.03);
	# prefer POSIX because of localized weekday names
	my $locale_charset = _guess_time_locale_charset();
	my $_weekdays = [];
	foreach my $day_i (6 .. 12) { # 2000-08-06 till 2000-08-12
	    my $wday = _decoded_strftime("%A", [0,0,0,$day_i,8-1,2000-1900], $locale_charset);
	    if ($wday eq '' || $wday =~ /^\?/) {
		die "Can't get weekday name from locale";
	    }
	    push @$_weekdays, $wday;
	}
	$weekdays = $_weekdays;
    };
    warn $@ if $@ && $DEBUG;
    if (!$weekdays) {
	$weekdays = $en_weekdays;
    }
    $weekdays;
}

sub _get_month_names {
    return $monthnames if $monthnames;
    eval {
	my $loc = _get_datetime_locale();
	my @monthnames = @{ $loc->can('month_format_wide') ? $loc->month_format_wide : $loc->month_names }; # clone!
	$monthnames = \@monthnames;
    };
    return $monthnames if $monthnames;
    warn $@ if $@ && $DEBUG;
    eval {
	require POSIX;
	# prefer POSIX because of localized month names
	my $locale_charset = _guess_time_locale_charset();
	my $_monthnames = [];
	foreach my $month_i (1 .. 12) {
	    my $mname = _decoded_strftime("%B", [0,0,0,1,$month_i-1,1970], $locale_charset);
	    if ($mname eq '' || $mname =~ /^\?/) {
		die "Can't get month name from locale";
	    }
	    push @$_monthnames, $mname;
	}
	$monthnames = $_monthnames;
    };
    if (!$monthnames) {
	$monthnames = $en_monthnames;
    }
    $monthnames;
}

sub _now {
    my($k) = @_;
    my @now = localtime;
    if    ($k eq 'y') { $now[5]+1900 }
    elsif ($k eq 'm') { $now[4]+1 }
    elsif ($k eq 'd') { $now[3] }
    elsif ($k eq 'H') { $now[2] }
    elsif ($k eq 'M') { $now[1] }
    elsif ($k eq 'S') { $now[0] }
    else { @now }
}

sub inc_date {
    my($dw, $fw, $inc, $current_nw) = @_;
    if ($inc != 0) { # $inc == 0: only check and correct date
	if (!$current_nw) {
	    $current_nw = $dw->focusCurrent;
	}
	if ($current_nw) {
	    # search the active numentry widget
	    foreach (@{$fw->{Sub}}) {
		if ($current_nw eq $dw->{Sub}{$_} or
		    ($current_nw->parent && $current_nw->parent eq $dw->{Sub}{$_})
		   ) {
		    $dw->set_date($_, $dw->get_date($_, 1)+$inc);
		    return;
		}
	    }
	}
    }

    my @check_order;
    if (defined $dw->{SubWidget}{'dateframe'} and
	$fw eq $dw->{SubWidget}{'dateframe'}) {
	@check_order = qw(d m y);
    } else {
	@check_order = qw(S M H);
    }

    # search an existing date entry field
    my $entry_field;
    foreach (@check_order) {
	if (defined $dw->{Sub}{$_}) {
	    $entry_field = $_;
	    last;
	}
    }
    if (defined $entry_field) {
	$dw->set_date($entry_field, $dw->get_date($entry_field, 1)+$inc);
    }
}

sub firebutton_command {
    my($w, $cw, $inc, $type) = @_;
    if ($w->{Configure}{-precommand}) {
	return unless $w->Callback(-precommand => $w, $type, $inc);
    }
    my $sub_w = $w->{Sub}{$type};
    $w->inc_date($cw, $inc, $sub_w);
    if ($w->{Configure}{-command}) {
	$w->Callback(-command => $w, $type, $inc);
    }
}

sub _fmt_to_array {
    my $fmt = shift;
    my @a = split(/(%\d*[dmyAHMS])/, $fmt);
    shift @a if $a[0] eq '';
    @a;
}

sub _begin_of_day {
    my $s = shift;
    my(@l) = localtime $s;
    timelocal(0,0,0,$l[3],$l[4],$l[5]);
}

sub _end_of_day {
    my $s = shift;
    my(@l) = localtime $s;
    timelocal(59,59,23,$l[3],$l[4],$l[5]);
}

sub _Destroyed {
    my $w = shift;
    if ($] >= 5.00452) {
	my $varref = $w->{Configure}{'-variable'};
	if (defined $varref) {
	    if (ref $varref eq 'SCALAR') {
		untie $$varref;
	    } elsif (ref $varref eq 'HASH') {
		untie %$varref;
	    } else {
		warn "Unexpected ref type for -variable: <" . ref $varref . ">";
	    }
	}
    }
    $w->SUPER::DESTROY($w);
}

# Call only if POSIX is already loaded
sub _guess_time_locale_charset {
    my $charset;
    my $locale_name = eval {
	# Is setlocale and LC_TIME available everywhere?
	POSIX::setlocale(POSIX::LC_TIME());
    };
    warn $@ if $@ && $DEBUG;
    my $full_locale_name = $locale_name;
    $locale_name =~ s{^[^.]+\.}{};
    $locale_name =~ s{\@.*}{};
    if ($locale_name) {
	if      ($locale_name =~ m{^utf-?8$}i) {
	    $charset = "utf-8";
	} elsif ($locale_name =~ m{^iso[-_]?8859-?(\d+)$}i) {
	    $charset = "iso-8859-$1";
	} elsif ($locale_name =~ m{^(?:cp|ansi)-?(\d+)$}i) {
	    $charset = "cp$1";
	} elsif ($locale_name =~ m{^koi8-.$}i) {
	    $charset = lc $locale_name;
	} elsif ($locale_name =~ m{^euc-?(cn|jp|kr)$}i) {
	    $charset = "euc-" . lc $1;
	} elsif ($locale_name =~ m{^euc$}i && $full_locale_name =~ m{(kr|cn|jp)}i) {
	    $charset = "euc-" . lc $1;
	} elsif ($locale_name =~ m{^gb-?18030$}i && eval { require Encode::HanExtra; 1; }) {
	    $charset = "gb18030";
	} elsif ($locale_name =~ m{^gb-?(\d+|k)$}i) {
	    $charset = "gb" . lc $1;
	} elsif ($locale_name =~ m{^big5-?hkscs$}i) {
	    $charset = "big5-hkscs";
	} elsif ($locale_name =~ m{^big5$}i) {
	    $charset = "big5";
	} elsif ($locale_name =~ m{^s(?:hift)?-?jis$}i) {
	    $charset = "shiftjis";
	} elsif ($locale_name =~ m{^(?:us-)?ascii$}i) {
	    $charset = "ascii";
	}
	## More encodings are missing:
	## (Following seen on FreeBSD 6.2)
	##   cp1131: http://source.icu-project.org/repos/icu/icu/trunk/source/data/mappings/ibm-1131_P100-1997.ucm
	##   iscii-dev
	##   armscii-8
	##   pt154 (kazachstan?)
	## (Following seen on Solaris 10)
	##   PCK (japanese)
	##   TIS620 (thai)
	##   BIG5HK
	##   zh_TW.EUC (use euc-cn?)
    }
    $charset;
}

# Call only if POSIX is already loaded
sub _decoded_strftime {
    my($fmt, $localtime_ref, $locale_charset) = @_;
    my $date_string = POSIX::strftime($fmt, @$localtime_ref);
    return $date_string if (!$locale_charset);
    eval {
	require Encode;
	$date_string = Encode::decode($locale_charset, $date_string, Encode::LEAVE_SRC());
    };
    warn $@ if $@ && $DEBUG;
    return $date_string;
   
}

sub _get_datetime_locale {
    require DateTime::Locale;
    require POSIX;
    my $locale_name = POSIX::setlocale(POSIX::LC_TIME());
    my $loc = DateTime::Locale->load($locale_name);
    $loc;
}

######################################################################

package Tk::Date::UnixTime;

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
    my(@t) = localtime $value;
    my $setdate = { 'S' => $t[0],
		    'M' => $t[1],
		    'H' => $t[2],
		    'd' => $t[3],
		    'm' => $t[4]+1,
		    'y' => $t[5]+1900,
		    'A' => $t[6]
		  };
    foreach (qw(y m d H M S)) { # umgekehrte Reihenfolge!
	$self->{Widget}->set_date($_, $setdate->{$_});
    }
}

sub FETCH {
    my $self = shift;
    $self->{Widget}->get("%s");
}

######################################################################

package Tk::Date::DateHash;

sub TIEHASH {
    my($class, $w, $init) = @_;
    my $self = {};
    $self->{Widget} = $w;
    bless $self, $class;
    if (defined $init) {
	while(my($k, $v) = each %$init) {
	    $self->STORE($k, $v);
	}
    }
    $self;
}

sub STORE {
    my($self, $field, $value) = @_;
    $self->{Widget}->set_date($field, $value);
}

sub FETCH {
    my($self, $field) = @_;
    $self->{Widget}->get_date($field, 1);
}

sub FIRSTKEY {
    my $self = shift;
    $self->{Key} = -1;
    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;
    return undef if (++$self->{Key} > 5);
    (qw(y m d H M S))[$self->{Key}];
}

######################################################################

1;

__END__

=head1 NAME

Tk::Date - a date/time widget for perl/Tk

=head1 SYNOPSIS

    use Tk::Date;
    $date_widget = $top->Date->pack;
    $date_widget->get("%x %X");

=head1 DESCRIPTION

Tk::Date implements a date/time widget. There are three ways to input
a date:

=over 4

=item * Using the keyboard to input the digits and the tab key or the mouse
pointer to move focus between fields.

=item * Using up and down cursor keys to increment/decrement the
date (only with installed Tk::NumEntryPlain widget).

=item * Selecting up and down arrow buttons will increment or decrement
the value of the active field (only with installed Tk::FireButton widget).

=back

=head2 The Date/Time Format

Unlike Java, Perl does not have a date/time object. However, it is
possible to use the unix time (seconds since epoch, that is 1st
January 1970) as a replacement. This is limited, since on most
architectures, the valid range is between 14th December 1901 and 19th
January 2038. For other dates, it is possible to use a hash notation:

    { y => year,
      m => month,
      d => day,
      H => hour,
      M => minute,
      S => second }

The abbreviations are derivated from the format letters of strftime.
Note that year is the full year (1998 instead of 98) and month is the
real month number, as opposed to the output of localtime(), where the
month is subtracted by one.

In this document, the first method will be referred as B<unixtime> and
the second method as B<datehash>.

=head1 STANDARD OPTIONS

Tk::Date descends from Frame and inherits all of its options.

=over 4

=item -orient

Specified orientation of the increment and decrements buttons. May be
vertical (default) or horizontal.

=back

=head1 WIDGET-SPECIFIC OPTIONS

Some options are only available if the prerequisite modules from the
Tk-GBARR distribution are installed too.

=over 4

=item -allarrows

If true then all entry fields will obtain arrows. Otherwise only one
arrow pair for each date and time will be drawn. This option can be
set only while creating the widget. This option needs the
L<Tk::NumEntry> widget to be installed.

=item -bell

Specifies a boolean value. If true then a bell will ring if the user
attempts to enter an illegal character (e.g. a non-digit).

=item -check

If set to a true value, Tk::Date makes sure that the user can't input
incorrect dates. This option can be set only while creating the
widget.

=item -choices

Creates an additional choice button. The argument to I<-choices> must
be one of C<now>, C<today>, C<yesterday> or C<tomorrow>, or an array
with a combination of those. If only one is used, only a simple button
is created, otherwise an optionmenu. This option can be set only while
creating the widget.

Examples:

	-choices => 'now'
	-choices => ['today', 'yesterday', 'tomorrow']

It is possible to specify user-defined values. User-defined values
should be defined as array elements with two elements. The first element
is the label for the button or optionmenu entry. The second element
specifies the time associated with this value. It may be either a date
hash (missing values are set to the current date) or a subroutine which
calculates unix seconds.

Here are two examples. The first defines an additional optionmenu
entry for this year's christmas and the second defines an entry for
the day before yesterday.

	-choices => ['today',
                     ['christmas' => { 'm' => 12, 'd' => 25}]
                    ]
        -choices => ['today',
		     'yesterday',
                     ['the day before yesterday' => sub { time()-86400*2 }]
                    ]

=item -command

Specifies a callback which is executed every time after an arrow
button is selected. The callback is called with the following
arguments: reference of date widget, field specifier, increment value.
The field specifier is either "date" or "time" or one of "H", "M",
"S", "d", "m", "y" for the possible time and date fields.

=item -datefmt

This is a sprintf/printf-like format string for setting the order and
format of the date entries. By default, the format string is
"%2d.%2m.%4y" meaning a two-character wide day entry, followed by a
dot, followed by a two-character wide month entry, another dot, and
finally a four-character wide year entry. The characters are the same
as in the strftime function (see L<POSIX>). It is also possible to use
the 'A' letter for displaying the (localized) weekday name. See below
in the EXAMPLES section for a more US-like date format. This option
can be set only while creating the widget.

=item -decbitmap

Sets the bitmap for the decrease button. Defaults to FireButton's default
decrease bitmap.

=item -editable

If set to a false value, disables editing of the date widget. All
entries are converted to labels and there are no arrow buttons.
Defaults to true (widget is editable). This option can be set only
while creating the widget.

=item -fields

Specifies which fields are constructed: date, time or both. Defaults
to both. This option can be set only while creating the widget.

=item -incbitmap

Sets the bitmap for the increase button. Defaults to FireButton's default
increase bitmap.

=item -monthmenu

Use an optionmenu for input of the month.

=item -monthnames

Replace the standard month names (either English or as supplied by
the locale system) with a user-defined array. The argument should be a
reference to a hash with 12 elements.

=item -precommand

Specifies a callback which is executed every time when an arrow button
is selected and before actually execute the increment or decrement
command. The callback is called with following arguments: date widget,
type (either C<date> or C<time>) and increment (+1 or -1). If the
callback returns with a false value, the increment or decrement
command will not be executed.

=item -readonly

"readonly" means only that the entry fields are readonly. However, the
user is still able to use the increment/decrement buttons to change
the date value. Use C<< -state => "disabled" >> to make a date widget
completely unchangable by the user.

=item -repeatinterval

Specifies the amount of time between invokations of the increment or
decrement. Defaults to 50 milliseconds.

=item -repeatdelay

Specifies the amount of time before the increment or decrement is first done
after the Button-1 is pressed over the widget. Defaults to 500 milliseconds.

=item -state

Specifies one of two states for the date widget: C<normal> or
C<disabled>. If the date widget is disabled then the value may not be
changed using the user interface (that is, by typing in the entry
subwidgets or pressing on the increment/decrement buttons).

=item -timefmt

This is a sprintf/printf-like format string for setting the order and
format of the time entries. By default, the format string is
"%2H.%2M.%2S" meaning a two-character wide hour entry, followed by a
dot, followed by a two-character wide minute entry, another dot, and
finally a two-character wide seconds entry. The characters are the
same as in the strftime function (see L<POSIX>). This option can be
set only while creating the widget.

=item -selectlabel

Change label text for choice menu. Defaults to 'Select:'. This option
can be set only while creating the widget.

=item -value

Sets an initial value for the widget. The argument may be B<unixtime>,
B<datehash> or B<now> (for the current time).

=item -varfmt

Specifies the format of the I<-variable> or I<-value> argument. May be
B<unixtime> (default) or B<datehash>. This option can be set only
while creating the widget.

=item -variable

Ties the specified variable to the widget. (See Bugs)

=item -weekdays

Replace the standard weekday names (either English or as supplied by
the locale system) with a user-defined array. The argument should be a
reference to a hash with seven elements. The names have to start with
Sunday.

=back

=head1 METHODS

The B<Date> widget supports the following non-standard method:

=over 4

=item B<get>([I<fmt>])

Gets the current value of the date widget. If I<fmt> is not given or
equal "%s", the returned value is in unix time (seconds since epoch).
This should work on all systems.

Otherwise, I<fmt> is a format string which is fed to B<strftime>.
B<strftime> needs the L<POSIX|POSIX> module installed and therefore
may not work on all systems.

=back

=head1 EXAMPLES

Display a date widget with only the date field in the format dd/mm/yyyy
and get the value in the same format:

  $date = $top->Date(-datefmt => '%2d/%2m/%4y',
	  	     -fields => 'date',
		     -value => 'now')->pack;
  # this "get" only works for systems with POSIX.pm
  $top->Button(-text => 'Get date',
	       -command => sub { warn $date->get("%d/%m/%Y") })->pack;

Use the datehash format instead of unixtime:

  $top->Date(-fields  => 'date',
	     -value   => {'d' => '13', 'm' => '12', 'y' => '1957'},
	     -varfmt => 'datehash',
	    )->pack;

=head1 NOTES

Please note that the full set of features only available, if the
Tk-GBARR distribution is also installed. However, the widget also
works without this distribution, only lacking the arrow buttons.

If the POSIX module is available, localised weekday and month names
will be used instead of English names. Otherwise you have to use the
-weekday and -monthnames options. The POSIX strftime function does not
work correctly before version 1.03 (that is, before 5.6.0), so this
feature is disabled for older perl versions.

=head1 BUGS/TODO

 - The -orient option can be only set while creating the widget. Also
   other options are only settable at create time.

 - waiting for a real perl Date/Time object
 - tie interface (-variable) does not work if the date widget gets destroyed
   (see uncommented DESTROY)
 - get and set must use the tied variable, otherwise tieying does no work
   at all
 - -from/-to is missing (limit) (or -minvalue, -maxvalue?)
 - range check (in DateNumEntryPlain::incdec)
 - am/pm
 - more interactive examples are needed for some design issues (how strong
   signal errors? ...)
 - check date-Function
 - optionally use Tk::DateEntry for the date part
 - -command is not fully implemented

=head1 SEE ALSO

L<Tk|Tk>, L<Tk::NumEntryPlain|Tk::NumEntryPlain>,
L<Tk::FireButton|Tk::FireButton>, L<POSIX|POSIX>

=head1 AUTHOR

Slaven Rezic <eserte@cs.tu-berlin.de>

=head1 COPYRIGHT

Copyright (C) 1997, 1998, 1999, 2000, 2001, 2005, 2007, 2008, 2010 Slaven Rezic.
All rights reserved. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
