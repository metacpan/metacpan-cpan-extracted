#*** Schedule.pm ***#
# Copyright (C) 2006 by Torsten Knorr
# torstenknorr@tiscali.de
# All rights reserved!
#-------------------------------------------------
 package Tk::Schedule;
#-------------------------------------------------
 use strict;
 use warnings;
 use Tk::Frame;
 use Tk::TimePick;
 use Tk::ChooseDate;
 use Time::Local qw(timelocal timelocal_nocheck);
 use Storable;
 use B::Deparse;
#-------------------------------------------------
 $Tk::Schedule::VERSION = '0.01';
 @Tk::Schedule::ISA = qw(Tk::Frame);
 Construct Tk::Widget "Schedule";
#-------------------------------------------------
 sub Populate
 	{
 	require Tk::Entry;
 	require Tk::Listbox;
 	require Tk::Button;
 	require Tk::Radiobutton;
#-------------------------------------------------
 	my ($s, $args) = @_;
#-------------------------------------------------
# -interval 
# time to check the action list in seconds
 	$s->{_interval} = (defined($args->{-interval}))		?
 		delete($args->{-interval})	: 10;

# -command	
# pointer to a subroutine which is called at scheduled times
# or an array reference
 	$s->{_command} = (defined($args->{-command}))	?
 		delete($args->{-command})	: sub { warn("\n--- NO action defined ---\n"); };

# -repeat		
# "once", "yearly", "monthly", "weekly", "daily", "hourly"
# maybe "minute" or "second" do not any sense
 	$s->{_repeat} = (defined($args->{-repeat}))		?
 		delete($args->{-repeat})	: "once";

# -comment
# a comment to show
 	$s->{_comment} = (defined($args->{-comment}))	?
 		delete($args->{-comment})	: "comment";

# -time
# for the case that the time is to be defined by the program
 	$s->{_scheduletime} = (defined($args->{-scheduletime}))		?
 		delete($args->{-scheduletime})	: time();

 	$s->SUPER::Populate($args);
#-------------------------------------------------
 	$s->{frame} = $s->Frame(
 		)->pack(
 		-side		=> "right"
 		);
#-------------------------------------------------
 	$s->{listbox} = $s->Scrolled(
 		"Listbox",
 		-width		=> 60,
 		)->pack(
 		-fill		=> 'y',
 		-side		=> "left",
 		);
#-------------------------------------------------
 	$s->{entry_comment} = $s->{frame}->Entry(
 		-textvariable	=> \$s->{_comment}
 		)->pack(
 		-fill		=> 'x'
 		);
#-------------------------------------------------
 	$s->{choose_date} = $s->{frame}->ChooseDate(
 		-dateformat	=> 2,
 		-textvariable	=> \$s->{date}
 		)->pack(
 		-fill		=> 'x',
 		);
 	my @t = localtime();
 	$s->{choose_date}->set(
 		y		=> ($t[5] + 1900),
 		m		=> ($t[4] + 1),
 		d		=> $t[3]
 		);
#-------------------------------------------------
 	$s->{time_pick} = $s->{frame}->TimePick(
 		)->pack(
 		);
 	$s->{time_pick}->Subwidget("EntryTime")->pack(
 		-fill		=> 'x'
 		);
#-------------------------------------------------
# "once", "yearly", "monthly", "weekly", "daily", "hourly"
 	$s->{radio_once} = $s->{frame}->Radiobutton(
 		-text		=> "once",
 		-variable		=> \$s->{_repeat},
 		-value		=> "once"
 		)->pack(
 		-anchor		=> 'w'
 		);
#-------------------------------------------------
 	$s->{radio_yearly} = $s->{frame}->Radiobutton(
 		-text		=> "yearly",
 		-variable		=> \$s->{_repeat},
 		-value		=> "yearly"
 		)->pack(
 		-anchor		=> 'w'
 		);
#-------------------------------------------------
 	$s->{radio_monthly} = $s->{frame}->Radiobutton(
 		-text		=> "monthly",
 		-variable		=> \$s->{_repeat},
 		-value		=> "monthly"
 		)->pack(
 		-anchor		=> 'w'
 		);
#-------------------------------------------------
 	$s->{radio_weekly} = $s->{frame}->Radiobutton(
 		-text		=> "weekly",
 		-variable		=> \$s->{_repeat},
 		-value		=> "weekly"
 		)->pack(
 		-anchor		=> 'w'
 		);
#-------------------------------------------------
 	$s->{radio_daily}	= $s->{frame}->Radiobutton(
 		-text		=> "daily",
 		-variable		=> \$s->{_repeat},
 		-value		=> "daily"
 		)->pack(
 		-anchor		=> 'w'
	 	);
#-------------------------------------------------
 	$s->{radio_hourly} = $s->{frame}->Radiobutton(
 		-text		=> "hourly",
 		-variable		=> \$s->{_repeat},
 		-value		=> "hourly"
 		)->pack(
 		-anchor		=> 'w'
 		);
#-------------------------------------------------
 	$s->{button_add} = $s->{frame}->Button(
 		-text		=> "Add Time",
 		-command	=> [\&AddTime, $s]
 		)->pack(
 		-fill		=> 'x'
 		);
#-------------------------------------------------
 	$s->{button_delete} = $s->{frame}->Button(
 		-text		=> "Delete Time",
 		-command	=> [\&DeleteTime, $s]
 		)->pack(
 		-fill		=> 'x'
 		);
#-------------------------------------------------
 	$s->{childs} = 
 		{
 		"ScheduleFrame"		=> $s->{frame},
 		"ScheduleEntryComment"	=> $s->{entry_comment},
 		"ScheduleChooseDate"	=> $s->{choose_date},
 		"ScheduleTimePick"	=> $s->{time_pick},
 		"ScheduleRadioOnce"	=> $s->{radio_once},
 		"ScheduleRadioYearly"	=> $s->{radio_yearly},
 		"ScheduleRadioMonthly"	=> $s->{radio_monthly},
 		"ScheduleRadioWeekly"	=> $s->{radio_weekly},
 		"ScheduleRadioDaily"	=> $s->{radio_daily},
 		"ScheduleRadioHourly"	=> $s->{radio_hourly},
 		"ScheduleListbox"	=> $s->{listbox},
 		"ScheduleButtonDelete"	=> $s->{button_delete},
 		"ScheduleButtonAdd"	=> $s->{button_add}
 		};
 	$s->Advertise($_, $s->{childs}{$_}) for(keys(%{$s->{childs}}));
 	$s->Delegates(
 		DEFAULT	=> $s->{listbox}
 		);
 	$s->ConfigSpecs(
 		-interval		=> [qw/METHOD interval Interval/, $s->{_interval}],
 		-command	=> [qw/METHOD command Command/, $s->{_command}],
 		-repeat		=> [qw/METHOD repeat Repeat/, $s->{_repeat}],
 		-comment	=> [qw/METHOD comment Comment/, $s->{_comment}],
 		-scheduletime	=> [qw/METHOD scheduletime Scheduletime/, $s->{_scheduletime}],
 		DEFAULT	=> ["ADVERTISED"]
 		);
#-------------------------------------------------
 	if(-f "schedule")
 		{
 		$s->{schedule} = retrieve("schedule");
 		}
 	else
 		{
 		$s->{schedule} = undef;
 		}
 	$s->ShowSchedule();
 	}
#-------------------------------------------------
 sub interval
 	{
 	my ($self, $seconds) = @_;
 	$self->{_interval} = $seconds;
 	$self->{repeat_id}->cancel() if(defined($self->{repeat_id}));
 	$self->{repeat_id} = $self->{listbox}->repeat(($seconds * 1000), [\&CheckForTime, $self]);
 	return($self->{repeat_id}); 
 	}
#-------------------------------------------------
 sub command
 	{
 	$_[0]->{_command} = $_[1];
 	return($_[0]->{_command});
 	}
#-------------------------------------------------
 sub repeat
 	{
 	$_[0]->{_repeat} = $_[1];
 	return($_[0]->{_repeat});
 	}
#-------------------------------------------------
 sub comment
 	{
 	$_[0]->{_comment} = $_[1];
 	return($_[0]->{_comment});
 	}
#-------------------------------------------------
 sub scheduletime
 	{
 	my ($self, $time) = @_;
 	$self->{_scheduletime} = $time;
 	my @t = localtime($time);
 	$self->{time_pick}->SetSeconds($t[0]);
 	$self->{time_pick}->SetMinutes($t[1]);
 	$self->{time_pick}->SetHours($t[2]);
 	$self->{choose_date}->set(
 		d	=> $t[3],
 		m	=> ($t[4] + 1),
 		y	=> ($t[5] + 1900)
 		);
 	return($self->{_scheduletime});
 	}
#-------------------------------------------------
 sub insert
 	{
 	my ($self, %args) = @_;
 	$self->{_command}	= $args{-command} if(defined($args{-command}));
 	$self->{_repeat}		= $args{-repeat} if(defined($args{-repeat}));
 	$self->{_comment}		= $args{-comment} if(defined($args{-comment}));
 	$self->scheduletime($args{-scheduletime}) if(defined($args{-scheduletime}));
 	$self->AddTime();
 	return(1);
 	}
#-------------------------------------------------
 sub CheckForTime
 	{
 	my ($self) = @_;
 	for my $schedule_time (keys(%{$self->{schedule}}))
 		{
 		if($schedule_time <= time())
 			{
 			my @temp_command = @{$self->{schedule}{$schedule_time}[0]};
 			my $code = shift(@temp_command);
 			my $ref_sub = sub { eval($code); };
 			if($@)
 				{
 				warn($@);
 				return(0);
 				}	
 			$ref_sub->(@temp_command);
 			$self->ReworkSchedule($schedule_time);
 			}
 		}
 	return(1);
 	}
#-------------------------------------------------
# "once", "yearly", "monthly", "weekly", "daily", "hourly"
 sub ReworkSchedule
 	{
 	my ($self, $schedule_time) = @_;
 	return(0) if(!(defined($self->{schedule}{$schedule_time})));
 	my $repeat = $self->{schedule}{$schedule_time}[1];
 	my @old_time = localtime($schedule_time);
 	SWITCH:
 		{
 		($repeat eq "once")	&& do
 			{
 			delete($self->{schedule}{$schedule_time});
 			$self->ShowSchedule();
 			last(SWITCH);
 			};
 		($repeat eq "hourly")	&& do
 			{
 			$old_time[2]++;
 			$self->{schedule}{timelocal_nocheck(@old_time)} = delete($self->{schedule}{$schedule_time});
 			$self->ShowSchedule();
 			last(SWITCH);
 			};
 		($repeat eq "daily")	&& do
 			{
 			$old_time[3]++;
 			$self->{schedule}{timelocal_nocheck(@old_time)} = delete($self->{schedule}{$schedule_time});
 			$self->ShowSchedule();
 			last(SWITCH);
 			};
 		($repeat eq "weekly")	&& do
 			{
 			$old_time[3] += 7;
 			$self->{schedule}{timelocal_nocheck(@old_time)} = delete($self->{schedule}{$schedule_time});
 			$self->ShowSchedule();
 			last(SWITCH);
 			};
 		($repeat eq "monthly")	&& do
 			{
 			if($old_time[4] >= 11)
 				{
 				$old_time[4] = 0;
 				$old_time[5]++;
 				}
 			else
 				{
 				$old_time[4]++;
 				}
 			$self->{schedule}{timelocal_nocheck(@old_time)} = delete($self->{schedule}{$schedule_time});
 			$self->ShowSchedule();
 			last(SWITCH);
 			};
 		($repeat eq "yearly")	&& do
 			{
 			$old_time[5]++;
 			$self->{schedule}{timelocal_nocheck(@old_time)} = delete($self->{schedule}{$schedule_time});
 			$self->ShowSchedule();
 			last(SWITCH);
 			};
 		warn("invalid repeat value\n");	
 		}
 	store($self->{schedule}, "schedule");
 	return(1);
 	}
#-------------------------------------------------
# $object->{schedule}{time} = [ref_code or ref_array, repeat, comment];
 sub AddTime
 	{
 	my ($self) = @_;
 	my @d = $self->{choose_date}->get();
 	my $t = timelocal(
 		$self->{time_pick}->GetSeconds(),
 		$self->{time_pick}->GetMinutes(),
 		$self->{time_pick}->GetHours(),
 		$d[2],
 		($d[1] - 1),
 		($d[0] - 1900)
 		);
 	$t++ while(defined($self->{schedule}{$t}));
 	my $deparse= B::Deparse->new();
 	if(ref($self->{_command}) eq "ARRAY")
 		{
 		my @temp_command = @{$self->{_command}};
 		my $code = $deparse->coderef2text(shift(@temp_command));
 		$self->{schedule}{$t} = [[$code, @temp_command], $self->{_repeat}, $self->{_comment}];
 		}
 	elsif(ref($self->{_command}) eq "CODE")
 		{
 		my $code = $deparse->coderef2text($self->{_command});
 		$self->{schedule}{$t} = [[$code], $self->{_repeat}, $self->{_comment}];
 		}
 	else
 		{
 		warn("\n--- $self->{_command} is neihter a ARRAY nor a CODE reference ---\n");
 		}
 	$self->ShowSchedule();
 	store($self->{schedule}, "schedule");
 	return(1);
 	}
#-------------------------------------------------
 sub ShowSchedule
 	{
 	my ($self) = @_;
 	$self->{listbox}->delete(0, "end");
 	my $number = 0;
 	for(sort { $a <=> $b } keys(%{$self->{schedule}}))
 		{
 		$self->{listbox}->insert(
 			"end",
 			localtime($_) . " $self->{schedule}{$_}[1] $self->{schedule}{$_}[2]"
 			);
 		$self->{number}[$number] = $_;
 		$number++;
 		}
 	return(1);
 	}
#-------------------------------------------------
 sub DeleteTime
 	{
 	my ($self) = @_;
 	my $number = ($self->{listbox}->curselection())[0];
 	delete($self->{schedule}{$self->{number}[$number]});
 	store($self->{schedule}, "schedule");
 	$self->ShowSchedule();
 	return(1);
 	}
#-------------------------------------------------
 sub DESTROY
 	{
 	print("\n" . ref($_[0]) . " object destroyed\n");
 	store($_[0]->{schedule}, "schedule");
 	}
#-------------------------------------------------
1;
__END__
#-------------------------------------------------

=head1 NAME

Tk::Schedule - Perl extension for a graphical user interface to carrying out tasks up to schedule

=head1 SYNOPSIS

 my $schedule = $parent->Schedule(options);

=head1 EXAMPLE

 use Tk;
 use Tk::Schedule;
 my $mw = MainWindow->new();
 my $s = $mw->Schedule(
 	-interval		=> 30,
 	-repeat		=> "once",
 	-command	=> sub { print("Hello World\n") for(1..10); },
 	-comment	=> "check Mail-Box"
 	)->pack();
 MainLoop();

=head1 SUPER-CLASS

Schedule is derived from the Frame class.
This megawidget is comprised of an
 	ChooseDate
	TimePick
 	Entry
 	Listbox
 	Button
	Radiobutton
allowing to create a schedule.

=head1 DESCRIPTION

With this Widget function at a certain time can be called.
A schedule can be made for longer periods.
The call of functions can be repeated in certain course of time.
Possible repetition times are:
 	hourly
 	daily
 	weekly
 	monthly
 	yearly
For seconds or minutes the functions 
$widget->after(time, call) or
$widget->repeat(time, call) 
can be better used.

=head1 CONSTRUCTOR AND INITIALIZATION

 my $s = $mw->Schedule(
 	-interval		=> 30,		# default 10
 	-repeat		=> "daily",	# default once
 	-comment	=> "send E-Mail to mail@addresse.com",
 	-command	=> sub { print("Hello World\n") for(1..10); },
 	# -command	=> [\&DownloadWebsite, $server, $agrs],
 	# -command	=> \&ShowPicture,
 	-scheduletime	=> time()
 	)->pack();

=head1 WIDGET SPECIFIC OPTINOS

All options not specified below are delegated to the Listbox widget.

=item -interval

After how much seconds the program checks the schedule.
default = 10

=item -command

A reference to a function or array.
The first element of the array must be a reference to a function.

=item -repeat

In which periods the call of the function is repeated.
Possible repetition times are:
"hourly", "daily", "weekly", "monthly", "yearly"
default "once" that does mean NO repetition

=item -comment

This comment is indicated in the list box.

=item -scheduletime

Time in seconds to indicate.
default return value of time();

=head1 INSERTED WIDGETS

=item ChooseDate

Popup Calendar with support for dates prior to 1970.
Author Jack Dunnigan 

=item TimePick

A graphical user interface to pick timestrings syntax mistake-secure.
Author Torsten Knorr

=item Button

=item Listbox

=item Radiobutton

=item Entry

=head1 ADVERTISED WIDGETS

The following widgets are advertised:

=item ScheduleFrame

=item ScheduleEntryComment

=item ScheduleChooseDate

=item ScheduleTimePick

=item ScheduleRadioOnce

=item ScheduleRadioYearly

=item ScheduleRadioMonthly

=item ScheduleRadioWeekly

=item ScheduleRadioDaily

=item ScheduleRadioHourly

=item ScheduleListbox

=item ScheduleButtonDelete

=item ScheduleButtonAdd

=head1 METHODS

The following functions should be used like private functions.

=item CheckForTime

=item ReworkSchedule

=item AddTime

=item ShowSchedule

=item DeleteTime

The following functions should be used like public functions.

=item insert

With this method you can add a task from the program.
As parameter you can use the options
 -repeat, -command, -comment or -scheduletime
in every combination.
$widget->insert();
$widget->insert(-repeat	=> "once");
$widget->insert(-command	=> sub { });
$widget->insert(-comment	=> "new task");
$widget->insert(-scheduletime => time());
$widget->insert(
 	-repeat		=> "hourly",
 	-command	=> sub { print("every hour\n"); },
 	-comment	=> "every hour",
 	-scheduletime	=> time()
 	);

=item scheduletime

Set the time to indicate.
$widget->scheduletime(time_in_seconds); or
$widget->configure(
 	-scheduletime	=> time()
 	);

=head1 WIDGET METHODS

Call configure to use the following functions.
$schedule->configure(
 	-interval		=> 20,
 	-command	=> \&DailyDuty,
 	-repeat		=> "daily",
 	-comment	=> "every day the same task",
 	-scheduletime	=> time(),
 	);

=item interval

=item command

=item repeat

=item comment

=item scheduletime

=head1 PREREQUISITES

=item Tk

=item Tk::Frame

=item Tk::Photo

=item Tk::TimePick

=item Tk::ChooseDate

=item Date::Calc

=item Bit::Vector

=item Carp::Clan

=item Time::Local

=item Storable

=item B::Deparse

=head2 EXPORT

None by default.

=head1 SEE ALSO

Tk::TimePick
Tk::ChooseDate

=head1 BUGS

 Maybe you'll find some. Please let me know.

=head1 AUTHOR

Torsten Knorr, E<lt>torsten@mshome.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Knorr
torstenknorr@tiscali.de
http://www.planet-interkom.de/t.knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.


=cut














