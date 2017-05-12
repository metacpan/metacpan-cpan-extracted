#*** TimePick.pm ***#
# Copyright (C) 2006 by Torsten Knorr
# torstenknorr@tiscali.de
# All rights reserved!
#-------------------------------------------------
 package Tk::TimePick;
#-------------------------------------------------
 use strict;
 use warnings;
 use Tk::Frame;
 use vars '$AUTOLOAD';
#-------------------------------------------------
 @Tk::TimePick::ISA = qw(Tk::Frame);
 $Tk::TimePick::VERSION = '0.02';
 Construct Tk::Widget "TimePick";
#-------------------------------------------------
 sub Populate
 	{
 	require Tk::Entry;
 	require Tk::Button;
 	my ($tp, $args) = @_;
#-------------------------------------------------
# -order
 	$tp->{_order} = (defined($args->{-order})) ? 
 		$tp->SetOrder(delete($args->{-order})) : "hms";
# -separator
 	$tp->{_separator} = (defined($args->{-separator})) ? 
 		delete($args->{-separator}) : ':';
# -maxhours
 	$tp->{_maxhours} = (defined($args->{-maxhours})) ? 
 		delete($args->{-maxhours}) : 23;
 	$tp->{_maxhours} = 23 if(!(($tp->{_maxhours} == 12) or ($tp->{_maxhours} == 23)));
# -seconds
 	$tp->{_seconds} = (defined($args->{-seconds})) ? 
 		delete($args->{-seconds}) : (localtime())[0];
# -minutes
 	$tp->{_minutes} = (defined($args->{-minutes})) ? 
 		delete($args->{-minutes}) : (localtime())[1];
# -hours
 	$tp->{_hours} = (defined($args->{-hours})) ? 
 		delete($args->{-minutes}) : (localtime())[2];
# -regextimeformat
 	$tp->{_regextimeformat} = (defined($args->{-regextimeformat})) ? 
 		delete($args->{-regextimeformat}) : qr/(\d{1,2})(.+?)(\d{1,2})(.+?)(\d{1,2})/o;
 	$tp->SUPER::Populate($args);
#-------------------------------------------------
 	$tp->{entry_time} = $tp->Entry(
 		-textvariable		=> \$tp->{_timestring},
 		-state			=> "disabled",
 		-disabledforeground	=> "#000000",
 		-disabledbackground	=> "#FFFFFF"
 		)->pack(
 		-side		=> "top",
 		);
#-------------------------------------------------
 	for(split(//, $tp->{_order}))
 		{
 		$tp->{_timestring} .= $tp->{_separator} if(defined($tp->{_timestring}));
 		SWITCH:
 			{
 			($_ eq 's')	&& do
 				{
  				$tp->{frame_seconds} = $tp->Frame(
 					-label		=> "Seconds",
					-relief		=> "groove",
 					-borderwidth	=> 2,
 					-background	=> "#0000FF"
 					)->pack(
 					-side		=> "left",
 					);
 				$tp->{_timestring} .= $tp->{_seconds};
 				last(SWITCH); 
 				};
 			($_ eq 'm')	&& do
 				{
  				$tp->{frame_minutes} = $tp->Frame(
 					-label		=> "Minutes",
					-relief		=> "groove",
 					-borderwidth	=> 2,
 					-background	=> "#0000FF"
 					)->pack(
 					-side		=> "left",
 					);
 				$tp->{_timestring} .= $tp->{_minutes};
 				last(SWITCH); 
 				};
 			($_ eq 'h')	&& do
 				{
  				$tp->{frame_hours} = $tp->Frame(
 					-label		=> "Hours",
					-relief		=> "groove",
 					-borderwidth	=> 2,
 					-background	=> "#0000FF"
 					)->pack(
 					-side		=> "left",
 					);
 				$tp->{_timestring} .= $tp->{_hours};
 				last(SWITCH); 
 				};
 			}
 		}
 	
#-------------------------------------------------
 my $timer_repeat;
 my $timer_after;
 	$tp->{button_seconds_reduce} = $tp->{frame_seconds}->Button(
 		-text		=> '<',
 		-command	=> [\&SecondsReduce, $tp]
 		)->pack(
 		-side		=> "left"
 		);
 	$tp->{button_seconds_reduce}->bind(
 		"<ButtonPress-1>", 
		sub 
 			{ 
 			$timer_after = $tp->after(
 				500, 
 				sub { $timer_repeat = $tp->repeat(100, [\&SecondsReduce, $tp]); }
 				);
 			}
 		);
 	$tp->{button_seconds_reduce}->bind(
 		"<ButtonRelease-1>", 
		sub 
 			{ 
 			$timer_after->cancel() if($timer_after); 
 			$timer_repeat->cancel() if($timer_repeat); 
 			}
 		);
#-------------------------------------------------
 	$tp->{button_seconds_increase} = $tp->{frame_seconds}->Button(
 		-text		=> '>',
 		-command	=> [\&SecondsIncrease, $tp]
 		)->pack(
 		-side		=> "left"
 		);
 	$tp->{button_seconds_increase}->bind(
 		"<ButtonPress-1>", 
 		sub 
 			{
 			$timer_after = $tp->after(
 				500, 
 				sub { $timer_repeat = $tp->repeat(100, [\&SecondsIncrease, $tp]); }
 				);
 			}
 		);
	 $tp->{button_seconds_increase}->bind(
 		"<ButtonRelease-1>", 
 		sub 
 			{
 			$timer_after->cancel() if($timer_after); 
 			$timer_repeat->cancel() if($timer_repeat); 
 			}
 		);
#-------------------------------------------------
 	$tp->{button_minutes_reduce} = $tp->{frame_minutes}->Button(
 		-text		=> '<',
 		-command	=> [\&MinutesReduce, $tp]
 		)->pack(
 		-side		=> "left"
 		);
 	$tp->{button_minutes_reduce}->bind(
 		"<ButtonPress-1>",
 		sub 
 			{
 			$timer_after = $tp->after(
 				500, 
 				sub { $timer_repeat = $tp->repeat(100, [\&MinutesReduce, $tp]); }
 				); 
 			}
 		);
 	$tp->{button_minutes_reduce}->bind(
 		"<ButtonRelease-1>",
 		sub 
 			{ 
 			$timer_after->cancel() if($timer_after);
 			$timer_repeat->cancel() if($timer_repeat); 
 			}
 		);
#-------------------------------------------------
 	$tp->{button_minutes_increase} = $tp->{frame_minutes}->Button(
 		-text		=> '>',
 		-command	=> [\&MinutesIncrease, $tp]
 		)->pack(
 		-side		=> "left"
 		);
 	$tp->{button_minutes_increase}->bind(
 		"<ButtonPress-1>",
 		sub 
 			{
 			$timer_after = $tp->after(
 				500, 
 				sub { $timer_repeat = $tp->repeat(100, [\&MinutesIncrease, $tp]); }
 				); 
 			}
 		);
 	$tp->{button_minutes_increase}->bind(
 		"<ButtonRelease-1>",
 		sub 
 			{ 
 			$timer_after->cancel() if($timer_after);
 			$timer_repeat->cancel() if($timer_repeat); 
 			}
 		);
#-------------------------------------------------
 	$tp->{button_hours_reduce} = $tp->{frame_hours}->Button(
 		-text		=> '<',
 		-command	=> [\&HoursReduce, $tp]
 		)->pack(
 		-side		=> "left"
 		);
 	$tp->{button_hours_reduce}->bind(
 		"<ButtonPress-1>",
 		sub 
 			{
 			$timer_after = $tp->after(
 				500,
 				sub { $timer_repeat = $tp->repeat(100, [\&HoursReduce, $tp]); }
 				);
 			}
 		);
 	$tp->{button_hours_reduce}->bind(
 		"<ButtonRelease-1>",
 		sub 
 			{
 			$timer_after->cancel() if($timer_after);
 			$timer_repeat->cancel() if($timer_repeat);
 			}
 		);
#-------------------------------------------------
 	$tp->{button_hours_increase} = $tp->{frame_hours}->Button(
 		-text		=> '>',
 		-command	=> [\&HoursIncrease, $tp]
 		)->pack(
 		-side		=> "left"
 		);
 	$tp->{button_hours_increase}->bind(
 		"<ButtonPress-1>",
 		sub 
 			{
 			$timer_after = $tp->after(
 				500,
 				sub { $timer_repeat = $tp->repeat(100, [\&HoursIncrease, $tp]); }
 				);
 			}
 		);
 	$tp->{button_hours_increase}->bind(
 		"<ButtonRelease-1>",
 		sub
 			{
 			$timer_after->cancel() if($timer_after);
 			$timer_repeat->cancel() if($timer_repeat);
 			}
 		);
#-------------------------------------------------
 	$tp->{childs} = 
 		{
 		"EntryTime"		=> $tp->{entry_time},
 		"FrameSeconds"		=> $tp->{frame_seconds},
 		"ButtonSecondsReduce"	=> $tp->{button_seconds_reduce},
 		"ButtonSecondsIncrease"	=> $tp->{button_seconds_increase},
 		"FrameMinutes"		=> $tp->{frame_minutes},
 		"ButtonMinutesReduce"	=> $tp->{button_minutes_reduce},
 		"ButtonMinutesIncrease"	=> $tp->{button_minutes_increase},
 		"FrameHours"		=> $tp->{frame_hours},
 		"ButtonHoursReduce"	=> $tp->{button_hours_reduce},
 		"ButtonHoursIncrease"	=> $tp->{button_hours_increase},
 		};
 	$tp->Advertise($_, $tp->{childs}{$_}) for(keys(%{$tp->{childs}}));
 	$tp->Delegates(
 		DEFAULT	=> $tp->{entry_time}
 		);
 	$tp->ConfigSpecs(
 		DEFAULT	=> ["ADVERTISED"]
 		);
 	}
#-------------------------------------------------
 sub insert
 	{
 	my ($self, $time) = @_;
 	return(0) if(!($time =~ m/$self->{_regextimeformat}/));
 	return(0) if(!($2 eq $4));
 	$self->{_separator} = $2;
 	$self->SetTime($1, $3, $5);
 	return(1);
 	}
#-------------------------------------------------
 sub SetTime
 	{
 	my ($self, @t) = @_;
 	my $index = 0;
 	$self->{_timestring} = undef;
 	for(split(//, $self->{_order}))
 		{
 		$self->{_timestring} .= $self->{_separator} if(defined($self->{_timestring}));
 		SWITCH:
 			{
 			($_ eq 'h')	&& do
 				{
 				$self->{_hours}		= $t[$index];
 				$self->{_timestring}	.= $t[$index];
 				last(SWITCH);
 				};
 			($_ eq 'm')	&& do
 				{
 				$self->{_minutes}		= $t[$index];
 				$self->{_timestring}	.= $t[$index];
 				last(SWITCH);
 				};
 			($_ eq 's')	&& do
 				{
 				$self->{_seconds}		= $t[$index];
 				$self->{_timestring}	.= $t[$index];
 				last(SWITCH);
 				};
 			}
 		$index++;
 		}
 	return(1);
 	}
#-------------------------------------------------
 sub GetTime
 	{
 	my ($self) = @_;
 	$self->{_timestring} = undef;
 	for(split(//, $self->{_order}))
 		{
 		$self->{_timestring} .= $self->{_separator} if(defined($self->{_timestring}));
 		SWITCH:
 			{
 			($_ eq 'h')	&& do
 				{
 				$self->{_timestring}	.= $self->{_hours};
 				last(SWITCH);
 				};
 			($_ eq 'm')	&& do
 				{
 				$self->{_timestring}	.= $self->{_minutes};
 				last(SWITCH);
 				};
 			($_ eq 's')	&& do
 				{
 				$self->{_timestring}	.= $self->{_seconds};
 				last(SWITCH);
 				};
 			}
 		}
 	return($self->{_timestring});
 	}
#-------------------------------------------------
 sub SetSeconds
 	{
 	return(0) if(($_[1] < 0) or ($_[1] > 59));
 	$_[0]->{_seconds} = $_[1];
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub SetMinutes
 	{
 	return(0) if(($_[1] < 0) or ($_[1] > 59));
 	$_[0]->{_minutes} = $_[1];
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub SetHours
 	{
 	return(0) if(($_[1] < 1) or ($_[1] > $_[0]->{_maxhours}));
 	$_[0]->{_hours} = $_[1];
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub SetOrder
 	{
 	for(qw/hms hsm smh shm msh mhs/)
 		{
 		if($_ eq $_[1])
 			{
 			$_[0]->{_order} = $_[1];
 			return($_[1]);
 			}
 		}
 	return("hms");
 	}
#-------------------------------------------------
 sub SetMaxHours
 	{
 	if(($_[1] == 12) or ($_[1] == 23))
 		{
 		$_[0]->{_maxhours} = $_[1];
 		}
 	else
 		{
 		$_[0]->{_maxhours} = 23;
 		}
 	return(1);
 	}
#-------------------------------------------------
 sub SecondsReduce
 	{
 	if($_[0]->{_seconds} <= 0) { $_[0]->{_seconds} = 59; }
 	else { $_[0]->{_seconds}--; }
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub SecondsIncrease
 	{
 	if($_[0]->{_seconds} >= 59) { $_[0]->{_seconds} = 0; }
 	else { $_[0]->{_seconds}++; }
	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub MinutesReduce
 	{
 	if($_[0]->{_minutes} <= 0) { $_[0]->{_minutes} = 59; }
 	else { $_[0]->{_minutes}--; }
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub MinutesIncrease
 	{
 	if($_[0]->{_minutes} >= 59) { $_[0]->{_minutes} = 0; }
 	else { $_[0]->{_minutes}++; }
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub HoursReduce
 	{
 	if($_[0]->{_hours} <= 0) { $_[0]->{_hours} = $_[0]->{_maxhours}; }
 	else { $_[0]->{_hours}--; }
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub HoursIncrease
 	{
 	if($_[0]->{_hours} >= $_[0]->{_maxhours}) { $_[0]->{_hours} = 0; }
 	else { $_[0]->{_hours}++; }
 	return($_[0]->GetTime());
 	}
#-------------------------------------------------
 sub AUTOLOAD
 	{
 	no strict "refs";
 	my ($self, $value) = @_;
 	if($AUTOLOAD =~ m/(?:\w|:)*::(?i:get)_*(\w+)/)
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(exists($self->{$attr}))
 			{
 			*{$AUTOLOAD} = sub
 				{
 				return($_[0]->{$attr});
 				};
 			return($self->{$attr});
 			}
 		else
 			{
 			warn("NO such attribute < $attr > called by $AUTOLOAD\n");
 			}
 		}
 	elsif($AUTOLOAD =~ m/(?:\w|:)*::(?i:set)_*(\w+)/)
 		{
 		my $attr = lc($1);
 		$attr = '_' . $attr;
 		if(exists($self->{$attr}))
 			{
 			*{$AUTOLOAD} = sub
 				{
 				$_[0]->{$attr} = $_[1];
 				return(1);
 				};
 			$self->{$attr} = $value;
 			return(1);
 			}
 		else
 			{
 			warn("NO such attribute < $attr > called by $AUTOLOAD\n");
 			}
 		}
 	else
 		{
 		warn("no such method < $AUTOLOAD >\n");
 		}
 	return(1);
 	}
#-------------------------------------------------
 sub DESTROY
 	{
 	print("\n" . ref($_[0]) . " object destroyed\n");
 	}
#-------------------------------------------------
1;
#-------------------------------------------------
__END__

=head1 NAME

Tk::TimePick - Perl extension for a graphical user interface to pick timestrings syntax mistake-secure

=head1 SYNOPSIS

 use Tk;
 use Tk::TimePick;
 my $mw = MainWindow->new();
 my $tp = $mw->TimePick()->pack();
 my $b = $mw->Button(
 	-text		=> "Time",
 	-command	=> sub 
 		{
 		my $time_as_string = $tp->GetTimeString();
 		# my $time_as_string = $tp->GetTime();
 		#***
 		# Here we do something with the time as string
 		#***
 		}
 	)->pack();
 MainLoop();

=head1 DESCRIPTION

 The module protect the application for syntax-mistakes,
 made by users, while insert time specifications.

=head1 CONSTRUCTOR AND INITIALIZATION
 
 use Tk;
 use Tk::TimePick;
 my $mw = MainWindow->new();
 my $tp = $mw->TimePick(
 	-order		=> "smh", 	# default = "hms"
 	-separator	=> "<>",		# default = ':'
 	-maxhours	=> 12,		# default = 23
 	-seconds		=> 30,		# default = (localtime())[0]
 	-minutes		=> 30,		# default = (localtime())[1]
 	-hours		=> 12,		# default = (localtime())[2]
 	-regextimeformat	=> qr/regex for time-string/ # default =  qr/(\d{1,2})(.+?)(\d{1,2})(.+?)(\d{1,2})/o
 	)->pack();
 $tp->Subwidget("EntryTime")->configure(
 	-font		=> "{Times New Roman} 18 {bold}"
 	);
 for(qw/
 	ButtonSecondsReduce
 	ButtonSecondsIncrease
 	ButtonMinutesReduce
 	ButtonMinutesIncrease
 	ButtonHoursReduce
 	ButtonHoursIncrease
 	/)
 	{
 	$tp->Subwidget($_)->configure(
 		-font		=> "{Times New Roman} 14 {bold}",
 		);
 	}
 for(qw/
 	FrameSeconds
 	FrameMinutes
 	FrameHours
 	/)
 	{
 	$tp->Subwidget($_)->configure(
 		-background	=> "#00FF00"
 		);
 	}
 MainLoop();

=head1 WIDGET SPECIFIC OPTINOS

=item -order

The order of hours, minutes and seconds.
 h = hours, m = minutes, s = seconds "hms" = hours:minutes:seconds (default = "hms")

=item -separator

 char or string between the numbers (default = ':')

=item -maxhours

 times in 23 or 12 hours (default = 23)

=item -seconds

 at the beginning indicated seconds

=item -minutes

 at the beginning indicated minutes

=item -hours

 at the beginning indicated hours

=item -regextimeformat

 a regular expression that fits onto the time format
 (default = qr/(\d{1,2})(.+?)(\d{1,2})(.+?)(\d{1,2})/o)

=head1 METHODS

=head2 all options can be set or get by the following methods

=item $object->SetOrder("hms")

=item $object->GetOrder();

=item $object->SetSeparator(':')

=item $object->GetSeparator();

=item $object->SetSeconds(20)

=item $object->GetSeconds()

=item $object->SetMinutes(45)

=item $object->GetMinutes()

=item $object->SetHours(7)

=item $object->GetHours()

=item $object->SetMaxHours(12)

=item $object->GetMaxHours()

=item $object->SetRegexTimeFormat(qr/(\d{1,2})(.+?)(\d{1,2})(.+?)(\d{1,2})/o)

=item $object->GetRegexTimeFormat()

=head2 with the following functions the time-string can be set or get

=item $object->SetTimeString("23:21:55")

=item $object->GetTimeString()

=item $object->SetTime(12, 44, 51)

=item $object->GetTime()

=head1 INSERTED WIDGETS

=item EntryTime

 shows the time
 no direct user inputs are possible

=item FrameSeconds

 contains the two buttons "ButtonSecondsReduce" and "ButtonSecondsIncrease"

=item ButtonSecondsReduce

 reduce the seconds

=item ButtonSecondsIncrease

 increase the seconds

=item FrameMinutes

 contains the two buttons "ButtonMinutesReduce" and "ButtonMinutesIncrease"

=item ButtonMinutesReduce

 reduce the minutes

=item ButtonMinutesIncrease

 increase the minutes

=item FrameHours

 contains the two buttons "ButtonHoursReduce" and "ButtonHoursIncrease"
	
=item ButtonHoursReduce

 reduce the hours

=item ButtonHoursIncrease
	
 increase the hours

=head2 EXPORT

 None by default.

=head1 SEE ALSO

 Tk::DatePick
 http://www.planet-interkom.de/t.knorr/index.html
 torstenknorr@tiscali.de

=head1 KEYWORDS

time, user interface, 

=head1 	BUGS

 Maybe you'll find some. Please let me know.

=head1 AUTHOR

Torsten Knorr, E<lt>torstenknorr@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.


=cut




