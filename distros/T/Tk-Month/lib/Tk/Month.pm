#! /usr/bin/env perl

use 5.014000;
use warnings;
use strict;

package Tk::Month;

our $VERSION = '1.8';

use vars qw(
	@year @Year %year %a2year
	@week @Week %week %a2week
	$day %firstday
);

use Carp;
use POSIX;
use Time::Local;
use Text::Abbrev;
use Tk;
use Tk::Widget;

use base qw/ Tk::Derived Tk::Frame /;

Construct Tk::Widget 'Month';

sub debug {};
#sub debug { print STDERR @_; };

;# ---------------------------------------------------------------------
;# class initialisation.
{
	$day		= 24*60*60;	# a day in seconds.
	%firstday	= ();		# first weekday in a month cache

	# set up week and month names.
	&setWeek();
	&setYear();
}

;# ---------------------------------------------------------------------

;## Constructor.  Uses new inherited from base class
sub Populate
{
	debug "args: @_\n";

	my $self = shift;

	$self->SUPER::Populate(@_);

	# Set up extra configuration
	$self->ConfigSpecs(
		'-month'	=> ['PASSIVE',undef,undef, ''],
		'-year'		=> ['PASSIVE',undef,undef, ''],
		'-command'	=> ['PASSIVE',undef,undef, \&defaultAction],
		'-press'	=> '-command',
		'-printformat'	=> ['PASSIVE',undef,undef, '%d %B %Y'],
		'-dayformat'	=> ['PASSIVE',undef,undef, '%d'],
		'-title'	=> ['PASSIVE',undef,undef, '%B %Y'],
		'-update'	=> ['PASSIVE',undef,undef, 0],
		#'-printcommand'	=> ['PASSIVE',undef,undef, \&defaultPrint],
		'-navigation'	=> ['PASSIVE',undef,undef, 1],
		'-side'		=> ['PASSIVE',undef,undef, 1],
		#'-close'	=> ['PASSIVE',undef,undef, $self],

		# configurable from Xdefaults file.
		'-includeall'	=> ['PASSIVE','includeall','IncludeAll', 1],
		'-showall'	=> ['PASSIVE','showall','ShowAll', 0],
		'-first'	=> ['PASSIVE','first','First', 0],
		'-buttonhighlightcolor'	=> ['PASSIVE','buttonhighlightcolor','ButtonHighlightColor', ''],
		'-buttonhighlightbackground'	=> ['PASSIVE','buttonhighlightbackground','ButtonHighlightBackground', ''],
		'-buttonfg'	=> ['PASSIVE','buttonfg','ButtonFg', ''],
		'-buttonbg'	=> ['PASSIVE','buttonbg','ButtonBg', ''],
		'-buttonbd'	=> ['PASSIVE','buttonbd','ButtonBd', ''],
		'-buttonrelief'	=> ['PASSIVE','buttonrelief','ButtonRelief', ''],
	);

	# Construct the subwidgets.
	$self->{frame} = $self->make();

	# decide when to tick.......
	my ($s, $m, $h) = localtime();
	my $wait = $day - (($h *60 + $m)*60 + $s) + 10;
	$self->after($wait, [ 'tick', $self, $day, ]);

	# return widget.
	$self;
}

# DoWhenIdle seems to be replaced by afterIdle in Tk800.018.
sub afterIdle { &DoWhenIdle; }

;## Update the widget when you get a chance.
sub DoWhenIdle
{
	debug "args: @_\n";

	my $self = shift;

	# refresh the widget.
	$self->refresh();

	# update the widget now?
	$self->update if ($self->cget(-update));
}

;# Create all the subwidgets needed for the month.
sub make
{
	debug "args: @_\n";

	my $self	= shift;

	my $width = 2;

	# First create all the buttons in a grid.

	# navigation row.
	$self->{title} = $self->Menubutton(
		-width		=> 15,
	)->grid(
		-row		=> 0,
		-column		=> 2,
		-columnspan	=> 4,
		-sticky		=> 'nsew',
	);


	# Positions (0,0), (0,1), (0,6), (0,7) are the
	# navigation buttons.

	# other buttons......
	for (my $c=0; $c<$#week+2; $c++)
	{
		for (my $r=1; $r<8; $r++)
		{
			$self->{'button'}->{$r}->{$c} =
				$self->Button(
					# width is in chars
					-width	=> $width,
					#-padx	=> 0,
					#-pady	=> 0,
				)->grid(
					'-row'		=> $r,
					'-column'	=> $c,
					'-sticky'	=> 'nsew',
				);
		}
	}

	# Lets set up aliases for these buttons.

	# week day headings.....
	for (my $c=1; $c<= 1+$#week; $c++)
	{
		$self->{week}->{$c} = $self->{'button'}->{1}->{$c};
	}

	# side buttons.
	#for (my $r=1; $r<8; $r++)
	#{
		#$self->{side}->{$r} = $self->{'button'}->{$r}->{0};
	#}

	# date buttons.
	for (my $c=1; $c<$#week+2; $c++)
	{
		for (my $r=2; $r<8; $r++)
		{
			$self->{date}->{$r}->{$c} = 
				$self->{'button'}->{$r}->{$c};
		}
	}

	$self;
}

;# Toggle the side buttons on the left side
sub side
{
	debug "args: @_\n";

	my $self = shift;

	my $navigation = $self->{side};
	my $width = 2;

	# Don't do anything if there is really nothing to do.
	return if (
		exists($self->{sideState}) &&
		$self->cget('-side') eq $self->{sideState}
	);
	$self->{sideState} = $self->cget('-side');

	# Positions (0,0), (1,0), (2,0),..., (5,0) are the
	# the side buttons.

	# side buttons.
	if ($self->cget('-side'))
	{
		debug "creating side buttons.\n";
		for (my $r=1; $r<8; $r++)
		{
			$self->{side}->{$r} = $self->{'button'}->{$r}->{0};
		}
	}
	else
	{
		debug "removing side buttons.\n";

		# remove the side buttons.
		for (my $r=1; $r<8; $r++)
		{
			next unless (exists($self->{'button'}->{$r}->{0}));
			$self->{'button'}->{$r}->{0}->destroy();
			delete($self->{'button'}->{$r}->{0});
		}
	}
}

;# Toggle the navigation buttons in the navigation frame.
sub navigate
{
	debug "args: @_\n";

	my $self = shift;

	my $navigation = $self->{navigation};
	my $width = 2;

	# Don't do anything if there is really nothing to do.
	return if (
		exists($self->{navigationState}) &&
		$self->cget('-navigation') eq $self->{navigationState}
	);
	$self->{navigationState} = $self->cget('-navigation');

	# Positions (0,0), (0,1), (0,6), (0,7) are the
	# the navigation buttons.

	# ... and recreate.
	if ($self->cget('-navigation'))
	{
		debug "creating navigation buttons.\n";

		$self->{'button'}->{0}->{0} = $self->Button(
			-text	=> '<<',
			-command=> [\&advance,$self, -1 - $#year ],
			-width	=> $width,
			#-padx	=> 0,
			#-pady	=> 0,
		)->grid(
			-row	=> 0,
			-column	=> 0,
			-sticky	=> 'nsew',
		);

		$self->{'button'}->{0}->{1} = $self->Button(
			-text	=> '<',
			-command=> [\&advance,$self, -1 ],
			-width	=> $width,
			#-padx	=> 0,
			#-pady	=> 0,
		)->grid(
			-row	=> 0,
			-column	=> 1,
			-sticky	=> 'nsew',
		);

		$self->{'button'}->{0}->{7} = $self->Button(
			-text	=> '>>',
			-command=> [\&advance,$self, 1+$#year ],
			-width	=> $width,
			#-padx	=> 0,
			#-pady	=> 0,
		)->grid(
			-row	=> 0,
			-column	=> 7,
			-sticky	=> 'nsew',
		);

		$self->{'button'}->{0}->{6} = $self->Button(
			-text	=> '>',
			-command=> [\&advance,$self, +1 ],
			-width	=> $width,
			#-padx	=> 0,
			#-pady	=> 0,
		)->grid(
			-row	=> 0,
			-column	=> 6,
			-sticky	=> 'nsew',
		);

		#---------------------------------
		# create a pulldown menu attached to the title.
		my $title = $self->{title};
		my $menu = $title->Menu(-tearoff => 0);
		$title->configure(-menu => $menu);


		# would like to set a pull down menu here to set the month.
		$menu->command(
			'-label'	=> 'Today',
			'-command'	=> [ 'configure', $self, '-month' => '', '-year' => '' ],
			'-underline'	=> 0,
		);

		my $mm = &Submenu($menu, 
			'-label'	=> 'Set month',
			'-underline'	=> 4,
		);
		$mm->command(
			'-label'	=> 'Current',
			'-command'	=> [ 'configure', $self, '-month' => '' ],
		);
		$mm->separator();
		for (@year)
		{
			debug "adding month '$_' to pull down menu.\n";
			$mm->command(
				'-label'	=> $_,
				'-command'	=> [ 'configure', $self, '-month' => $_ ],
			);
		}

		my $ym = &Submenu($menu,
			'-label'	=> 'Set year',
			'-underline'	=> 4,
		);

		my $i;
		#my $year = $self->cget('-year');
		my $year = POSIX::strftime('%Y', localtime());
		$ym->command(
			'-label'	=> 'Current',
			'-command'	=> [ 'configure', $self, '-year' => '' ],
		);
		$ym->separator();
		for ($i = -5; $i<6; ++$i)
		{
			$ym->command(
				'-label'	=> $year+$i,
				'-command'	=> [ 'configure', $self, '-year' => $year+$i ],
			);
		}

		my $fm = &Submenu($menu,
			'-label'	=> 'First day of week',
			'-underline'	=> 0,
		);

		for (@week)
		{
			debug "radio button label is '$_'.\n";
			$fm->radiobutton(
				'-label'	=> $_,
				'-variable'	=> \$self->{Configure}->{-first},
				'-value'	=> &weekday2number($_),
				'-command'	=> [ 'refresh', $self ],
			);
		}

		$menu->checkbutton(
			'-label'	=> 'Include all',
			'-variable'	=> \$self->{Configure}->{'-includeall'},
			'-command'	=> [ 'refresh', $self ],
			'-underline'	=> 0,
		);
		
		$menu->checkbutton(
			'-label'	=> 'Show all',
			'-variable'	=> \$self->{Configure}->{'-showall'},
			'-command'	=> [ 'refresh', $self ],
			'-underline'	=> 0,
		);
		
		if (0) {
		$menu->command(
			'-label'        => 'Print month',
			'-command'      => [ sub {
				return unless ($self->cget(-printcommand));
				&{$self->cget(-printcommand)}($self->{month}, $self->{year}, $self->{first});
					} ],
			'-underline'	=> 0,
		);

		$menu->command(
			'-label'        => 'Close',
			'-command'      => [ sub { (shift)->cget('-close')->destroy(); }, $self ],
			'-underline'	=> 0,
		);
		}

	}
	else
	{
		debug "removing navigation buttons.\n";

		# remove the navigation buttons.
		local ($_);
		for (0,1,6,7)
		{
			next unless (exists($self->{'button'}->{0}->{$_}));
			$self->{'button'}->{0}->{$_}->destroy();
			delete($self->{'button'}->{0}->{$_});
		}

		# destroy the pull-down menu.
		my $menu = $self->{'title'}->cget('-menu');
		$menu->destroy() if ($menu);
		$self->{'title'}->configure('-menu' => undef)
	}

	debug "Title widget is now $self->{title}.\n";

	#$title;
}

;# Refreshes the calendar widget as it should be with respect to
;# the current values of its configuration.
sub refresh
{
	my $self = shift;

	# week day cache of first day of month/year.
	# get various information from the object.
	my $month	= &month2number($self->cget('-month'));
	my $year	= &year2number($self->cget('-year'));
	my $command	= $self->cget('-command');
	my $title	= $self->cget('-title');
	my $printformat	= $self->cget('-printformat');
	my $dayformat	= $self->cget('-dayformat');
	my $first	= $self->cget('-first');

	debug "refresh: month is $month and year is $year.\n";
	debug "first = '$first'.\n";

	# check that the object still actually exists.....
	unless ($self->{title}->IsWidget())
	{
		debug "$self is no longer a widget!\n";

		# bail out now.
		return;
	}

	##### Deal with navigation first.... ####
	$self->navigate();
	$self->side();

	############ Refresh the widget. ###################

	##### Work out the offset for the first day in month.
	my $offset	= &firstday($month, $year) - $first;
	debug "$month, $year offset = $offset\n";

	# remember the month, year and first for print function.
	$self->{month} = $month;
	$self->{year} = $year;
	$self->{first} = $first;

	# correct for a negative offset.
	$offset += 1 + $#week if ($offset < 0);

	debug "after negative correction: offset = $offset\n";

	##### fix midday for the first day of month.
	my $start = timelocal(0, 0, 12, 1, $month, $year-1900);

	# Get the correct current date.
	my $today = join('-', (localtime())[3,4,5]);
	debug "today is '$today'\n";

	# Deal with the title button...
	$title = POSIX::strftime($title, localtime($start));
	$self->{title}->configure('-text' => $title);

	# rewind to first day in grid.
	$start -= $day*$offset;

	# Take colours from the title button.....
	my $fg = $self->{title}->cget('-fg');
	my $bg = $self->{title}->cget('-bg');

	# other configuarations.
	my @config = ();
	local ($_);
	for (qw(fg bg highlightcolor highlightbackground bd relief))
	{
		next unless ($self->cget("-button$_"));
		push(@config, "-$_", $self->cget("-button$_"));
	}
	debug "extra config = (@config)\n";

	# configure the top left button.
	if (Exists($self->{'button'}->{1}->{0}))
	{
	$self->{'button'}->{1}->{0}->configure(
		'-text'		=> '?',
		'-command'	=> [ $command, $title, ( [ POSIX::strftime($printformat, localtime()) ] ) ],
		'-fg'		=> $fg,
		'-bg'		=> $bg,
		@config,
	);
	}

	# length of the week.
	my $weeklen = $#week + 1;
	debug "weeklen = $weeklen\n";

	my @when	= ();	# matrix of whens...


	# fill in the dates.
	for (my $i=1; $i<=42; ++$i)
	{
		my @lt = localtime($start);
		my $when = POSIX::strftime($printformat, @lt);

		debug "setting button for '$when'.\n";

		my $col = ($i-1) % $weeklen;
		my $row = int(($i-1)/$weeklen);

		# remember.....
		if ($self->cget('-includeall') || ($lt[4] == $month))
		{
			# pack a matrix of 'when's.
			$when[$row][$col] = $when;

			debug "including $when.\n";
		}
		
		my $thisdate = POSIX::strftime($dayformat, @lt);
		$thisdate = '' unless ($self->cget('-showall') || ($lt[4] == $month));

		my $button = $self->{'date'}->{$row+2}->{$col+1};
		$button->configure(
			'-text'		=> $thisdate,
			'-command'	=> [ $command, $title, ( [ $when ] ) ],
			'-fg'		=> $fg,
			'-bg'		=> $bg,
			@config,
		);

		# if it is today, reverse the colours.
		my $thisday = join('-', (@lt)[3,4,5]);
		debug "thisday is '$thisday'.\n";
		if ($today eq $thisday )
		{
			$button->configure('-fg'=>$bg, '-bg'=>$fg);
			debug "swapping colours for $today.\n";
		}

		# next day......
		$start += $day;
	}

	######## configure the week day headings. ##############
	my @fortnight = (@week, @week);
	for (my $c=1; $c<=1+$#week; $c++)
	{
		my $wday	= $fortnight[$c-1+$first];

		# grab a column from @when....
		local ($_);
		my @dates	= map { [ @{ $when[$_] } [ $c-1 ] ] } 0 .. $#when;

		debug "Weekday position (0, $c) [$wday] -> @dates.\n";

		$self->{week}->{$c}->configure(
			'-text'		=> $fortnight[$c-1+$first],
			'-command'	=> [ $command, $title, @dates ],
			'-fg'		=> $fg,
			'-bg'		=> $bg,
			@config,
		);
	}

	######## configure the week side buttons. ##############
	for (my $r=0; $r<6; $r++)
	{
		my $button	= $self->{side}->{$r+2};
		my @dates	= @{ $when[$r] ? $when[$r] : [] };

		next unless Exists($button);

		# this debug causes uninitialised warnings....
		#debug "Week position ($r, 0) => (@dates)\n";

		if (@dates)
		{
			$button->configure(
				'-command'	=> [ $command, $title, [ @dates  ]],
				'-text'		=> '=>',
				'-fg'		=> $fg,
				'-bg'		=> $bg,
				@config,
			);
		}
		else
		{
			$button->configure(
				'-command'	=> undef,
				'-text'		=> '',
				'-fg'		=> $fg,
				'-bg'		=> $bg,
				@config,
			);
		}
	}

	########### overload botton-right button. ################
	my $button	= $self->{'date'}->{7}->{7};
	if ($self->cget('-side'))
	{
		$button->configure(
			'-command'	=> [ $command, $title, @when ],
			'-text'		=> 'A',
			'-fg'		=> $fg,
			'-bg'		=> $bg,
			@config,
		);
	}
	else
	{
		$button->configure(
			'-command'	=> undef,
			'-text'		=> '',
			'-fg'		=> $fg,
			'-bg'		=> $bg,
			@config,
		);
	}


	debug "done\n";
}

;# increment and decrement the displayed month.
sub advance
{
	debug "args: @_\n";

	my ($self, $inc)	= @_;

	my $month	= &month2number($self->cget('-month'));
	my $year	= &year2number($self->cget('-year'));


	debug "before: month = $month, year = $year\n";
	$month += $inc;
	debug "after inc: month = $month, year = $year\n";

	# How many months in a year?
	my $nm = 1 + $#year;

	# roll forward or back as needed.
	while ($month >= $nm)	{ $year ++; $month -= $nm; }
	while ($month < 0)	{ $year --; $month += $nm; }

	debug "after: month = $month, year = $year\n";

	#$self->configure('-month'=>$year[$month], '-year'=>$year);
	$self->configure('-month'=>$month, '-year'=>$year);
}

;# create a sub menu ,,,,,,
sub Submenu
{
	my $menu = shift;

	my %info;

	# inherit defaults...
	$info{'-tearoff'}	= $menu->cget('-tearoff');

	# overload defaults...
	while (@_)
	{
		$_ = shift;
		if (/^\-/)	{ $info{$_} = shift; }
		else		{ unshift(@_, $_); last; }
	}

	my $submenu = $menu->Menu(
		-tearoff	=> "$info{'-tearoff'}",
	);

	my $c = $menu->cascade( %info );
	$c->configure(-menu => $submenu);

	$submenu;
}

# set up the weekday information.
# pass the desired weekday names as arguments.
sub setWeek
{
	debug "args: @_\n";

	# days of the week.
	@week = @_;
	@week = &abreviatedWeekDays() unless @week;
	%week = &invert(@week);
	%a2week = abbrev(LC(@week));
}

# set up the month information.
# pass the desired month names as arguments.
sub setYear
{
	# months of the year.
	@year = @_;
	@year = &months() unless @year;
	%year = &invert(@year);
	%a2year = abbrev(LC(@year));
}

# convert weekday to number.
sub weekday2number
{
	my ($arg) = @_;

	$arg = lc($arg);

	debug "arg is now '$arg'\n";

	# deal with abbreviations first....
	$arg = $a2week{$arg} if (exists($a2week{$arg}));
	debug "unabbreviated arg '$arg'.\n";

	if (!defined($arg) || $arg eq '')
	{
		# undefined or empty ... return current.
		$arg = (localtime())[6];
	}
	elsif ($arg =~ /^-?\d+$/)
	{
		# if its a number.....
		$arg %= (1 + $#week);
		$arg += (1 + $#week) if ($arg < 0);
		return $arg;
	}

	# look it up in the reverse array.
	return $week{$arg} if (exists($week{$arg}));

	# return current.... odd choice?
	(localtime())[6];
}

# return lowercase version of array.....
sub LC
{
	my @a;
	for my $a (@_)
	{
		push (@a, lc($a));
	}

	@a;
}

# convert month to number.
sub month2number
{
	my ($arg) = @_;

	$arg = '' unless (defined($arg));

	debug "arg '$arg'.\n";

	$arg = lc($arg);

	# deal with abbreviations first....
	$arg = $a2year{$arg} if (exists($a2year{$arg}));
	debug "unabbreviated arg '$arg'.\n";

	if (!defined($arg) || $arg eq '')
	{
		# undefined or empty ... return current.
		$arg = (localtime())[4];
	}
	elsif ($arg =~ /^-?\d+$/)
	{
		debug "its the number $arg\n";
		# if its a number.....
		$arg %= (1 + $#year);
		debug "modulo .... its $arg\n";
		$arg += (1 + $#year) if ($arg < 0);

		debug "finally its $arg\n";
	}
	elsif (exists($year{$arg}))
	{
		# look it up in the reverse array.
		$arg = $year{$arg};
	}
	else
	{
		# return current... odd choice?
		$arg = (localtime())[4];
	}

	debug "returns '$arg'.\n";

	$arg;
}

# convert a year to a number......
sub year2number
{
	my ($arg) = @_;

	$arg = '' unless (defined($arg));

	debug "arg '$arg'.\n";

	if (!defined($arg) || $arg eq '')
	{
		# undefined or empty ... return current.
		$arg = (localtime())[5] + 1900;
	}
	elsif ($arg =~ /^-?\d+$/)
	{
		debug "its a number - $arg\n";
	}
	else
	{
		# catch all.
		$arg = (localtime())[5] + 1900;
	}

	$arg;
}

# Take an array and return the inverse associative array.
sub invert
{
	#warn "args: @_\n";

	my %i = ();
	for (my $i=0; $i<=$#_; ++$i)
	{
		$i{lc($_[$i])} = $i;
	}

	#warn "args: ", %i, "\n";

	%i;
}

;# ---------------------------------------------------------------------
;# return weekday for the first day of a month.
sub firstday
{
	my $m = shift;
	my $y = shift;

	debug "firstday: $m $y\n";

	$m = &month2number($m);

	debug "firstday: $m $y\n";

	unless (defined($firstday{$y}->{$m}))
	{
    		my $t = timelocal (0,0,12,1,$m,$y-1900,0,0,0);
		$firstday{$y}->{$m} = (localtime($t))[6];

	}

	debug "first day of $m $y is " . $firstday{$y}->{$m} . "\n";

	$firstday{$y}->{$m};

}

;# Return the abreviated week days.
sub abreviatedWeekDays
{
	my @week = ();

	my $now = time;
	my ($s, $m, $h, $wd) = (localtime($now))[0,1,2,6];

	# adjust...
	$now -= (($h-12)*60+$m)*60+$s;	# to midday.
	$now -= $wd * $day;

	# start looking for the days of the week.
	# the first one is ....
	$week[0] = POSIX::strftime("%a", localtime($now));

	for (my $i=1 ; ; ++$i)
	{
		# what's the next week day?
		$now += $day;
		my $tmp = POSIX::strftime("%a", localtime($now));

		# Have we done a whole week yet?
		last if ($tmp eq $week[0]);

		# its a new one!
		$week[$i] = $tmp;
	}
	debug "the week is @week.\n";

	@week;
}

# generate the months of the year.
sub months
{
	my @year = ();

	my $now = time;
	my ($s, $m, $h, $yd) = (localtime($now))[0,1,2,7];

	# adjust...
	$now -= (($h-12)*60+$m)*60+$s;	# to midday.
	$now -= $yd * $day;		# 1st Jan.

	# start looking for the months of the year.
	# the first one is ....
	$year[0] = POSIX::strftime("%B", localtime($now));

	for (my $i=1 ; ; ++$i)
	{
		# what's the next month?
		$now += 32*$day;
		my $tmp = POSIX::strftime("%B", localtime($now));

		# Have we done a whole year yet?
		last if ($tmp eq $year[0]);

		# its a new one!
		$year[$i] = $tmp;
	}
	debug "the week is @week.\n";

	warn "Tk::Month::months year has only $#year months!\n" if ($#year != 11);
	@year;
}

;# This runs occationally updating the calendar.
sub tick
{
	debug "args: ", @_, "\n";

	# remember the period
	my $self	= shift;
	my $p		= shift;

	debug "tick period is $p msecs.\n";

	# check that the object still actually exists.....
	unless ($self->{title}->IsWidget())
	{
		debug "$self is no longer a widget!\n";

		# bail out now.
		return undef;
	}

	# update it.
	$self->refresh();

	# ... and keep doing it!
	$self->after($p, [ 'tick', $self, $p, ]);
}

;# the default button press action.
sub defaultAction
{
	my ($title, @x) = @_;

	my $header = '-'x20 . $title . '-'x20;
	print $header, "\n";

	for my $i ( 0 .. $#x )
	{
		for my $j ( 0 .. $#{$x[$i]} )
		{
			#print "elt $i $j is $x[$i][$j]\n";
			if (defined($x[$i][$j]))
			{
				print "\t$x[$i][$j]";
			}
			else
			{
				print "\t.";
			}
		}
		print "\n";
	}
	$header =~ s/./-/g;
	print $header, "\n";
								     
	#print join(', ', @_) . "\n";
}

#sub defaultPrint { print "@_\n"; }

# Add an entry to the title menu.
sub command 
{
	my $self = shift;

	unless ($self->{title}->IsWidget())
	{
		debug "$self is no longer a widget!\n";
		return;
	}

	$self->{title}->command(@_);
}

# Add a separator to the title menu.
sub separator
{
	my $self = shift;

	unless ($self->{title}->IsWidget())
	{
		debug "$self is no longer a widget!\n";
		return;
	}

	$self->{title}->separator(@_);
}

;#################################################################
;# A default startup routine.
sub TkMonth
{
	# only use this when testing.
	eval 'use Getopt::Long;';
	Getopt::Long::Configure("pass_through");
	GetOptions(
		'd'	=> sub { 
			eval '	sub debug {
				my ($package, $filename, $line,
					$subroutine, $hasargs, $wantargs) = caller(1);
				$line = (caller(0))[2];
		
				print STDERR "$subroutine: ";
		
				if (@_) {print STDERR @_; }
				else    {print "Debug $filename line $line.\n";}
			};
			';
		},
	);

	my ($month, $year) = (localtime(time))[4,5];
	$year += 1900;

	# Test script for the Tk Tk::Month widget.
	use Tk;
	use Tk::Optionmenu;
	#use Tk::Month;

	my $top=MainWindow->new();

	my $f = $top->Frame()->pack(
			-side	=> 'top',
			-fill	=> 'x',
			-expand => 'yes',
	);
	my $m = $f->Menubutton(
		'-text'		=> 'File',
	)->pack(
		-side	=> 'left',
	);

	#########################################################
	# can set the week days here but not recommended.
	# Tk::Month::setWeek( qw(Su M Tu W Th F Sa) );

	my $a = $top->Month(
		'-printformat'	=> '%a %d',
		#'-dayformat'	=> '%j',
		'-includeall'	=> 0,
		'-month'	=> $month,
		'-year'		=> $year,
	@ARGV,
	)->pack();

	$a->configure(@_) if @_;

	$a->separator();
	$a->command(
		-label		=> 'Print month',
		-command	=> [ sub { my $s = shift; print $s->cget('-month'), " ", $s->cget('-year'), "\n"; }, $a, ],
		-underline	=> 0,
	);
	$a->command(
		-label        => 'Close',
		-command      => [ sub { (shift)->destroy(); }, $a ],
		-underline	=> 0,
	);
	#########################################################

	# modify the month....
	$m->command(
		-label		=> 'New',
		-command	=> sub { $top->Month()->pack(); },
	);

	$m->separator();

	for my $i ( qw(raised flat sunken) )
	{
		$m->command(
			-label		=> ucfirst($i),
			-command	=> sub { $a->configure(-buttonrelief => $i); },
		);
	}

	$m->separator();

	for my $i ( qw(on off) )
	{
		$m->command(
			-label		=> "Navigation $i",
			-command	=> sub { $a->configure(-navigation => ($i eq 'on' ? 1 : 0)); },
		);
	}

	for my $i ( qw(on off) )
	{
		$m->command(
			-label		=> "Side $i",
			-command	=> sub { $a->configure(-side => ($i eq 'on' ? 1 : 0)); },
		);
	}

	for my $i ( qw(%e %d %j) )
	{
		$m->command(
			-label		=> "Day format $i",
			-command	=> sub { $a->configure(-dayformat => $i); },
		);
	}

	$m->separator();
	$m->command(
		-label		=> 'Exit',
		-command	=> sub { exit; },
	);

	MainLoop();

}

# If we are running this file then run the test function....
&TkMonth if ($0 eq __FILE__);

1;

__END__

=head1 NAME

Tk::Month - Calendar widget which shows one month at a time.

=head1 SYNOPSIS

  use Tk;
  use Tk::Month;

  $m = $parent->Month(
		-month		=> 'July',
		-year		=> '1997',
		-title		=> '%b %y',
		-command	=> \&press,
		-printformat=> '%d',
		-navigation	=> [0|1],
		-includeall	=> [0|1],
		-showall	=> [0|1],
		-first		=> [0|1|2|3|4|5|6],
	)->pack();

  $m->configure(
		-month		=> 'July',
		-year		=> '1997',
		-command	=> \&press,
		-printformat=> '%d %B %Y %A',
		-navigation	=> [0|1],
		-includeall	=> [0|1],
		-showall	=> [0|1],
		-first		=> [0|1|2|3|4|5|6],
  );

  $m->separator();
  $m->command(
		-label		=> 'Label',
		-command	=> \&callback,
  );

=head1 DESCRIPTION 

C<Tk::Month> is a general purpose calendar widget
which shows one month at a time and allows
user defined button actions.

=head1 METHODS

=head2 $m->separator();

Adds a separator to the title menu.

=head2 $m->command(...);

Adds an entry to the title menu. This can be used to add 
extra functionality, such as closing the calendar widget or
printing a month.

=over 3

=back 

=head1 OPTIONS

=head2 -month => 'month'

Sets the required month. The default is the current month.

=head2 -year => 'year'

Sets the required year. The default is the current year.

=head2 -title => 'strftime format'

Sets the format for the widget title.
The default is C<%B %Y>.

=head2 -command => \&press

Set the command to execute when a button is pressed.
This function must accept a string
(the title of the Month widget)
and an array of arrays of dates.
Each date is of the format specified by the -printformat option.
The default is to print out the list on standard output.

=head2 -printformat	=> "strftime format"

Set the default format for dates when they are passed in an
array of arrays to the -command function.
The default is C<%d %B %Y>.

=head2 -dayformat	=> "strftime format"

Set the default format for the days within the widget.
The default is C<%d>, i.e. the date of each day.

=head2 -showall		=> [0|1]

Causes the dates on buttons not actually in the month to be
dsiplay. The default is to not show these dates.

=head2 -includeall	=> [0|1]

Causes the side buttons to include all the non-month dates.
The defaults is to include all the dates.

=head2 -first	=> [0|1|2|3|4|5|6]

Sets the first day of the week.
The default is C<0> (i.e. Sunday).

=head2 -navigation	=> [0|1],

Sets whether the navigation buttons and menu are included.
The default is to show the naviagation aids.

=head2 -side	=> [0|1],

Sets whether the side buttons are included.
The default is to show the side button aids.

=head1 SEE ALSO

See L<Tk> for Perl/Tk documentation.

See L<Tk::MiniCalendar> for another Perl/Tk calendar widget
implementation.

=head1 AUTHOR

Anthony R Fletcher, E<lt>a r i f 'a-t' c p a n . o r gE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1998-2014 by Anthony R Fletcher.
All rights reserved.
Please retain my name on any bits taken from this code.
This code is supplied as-is - use at your own risk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

