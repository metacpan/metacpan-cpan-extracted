
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::SchedEvent;

use Time::ParseDate;
use POSIX;

use strict;

use Astro::SunTime;

sub new
{
   my $type = shift;

   my $self = bless { @_ }, $type;

   unless ($self->{macro} && $self->{macro}->isa('X10::Macro'))
   {
      warn "No macro sent to create SchedEvent";
      return undef;
   }

   $self->{verbose} = 1 if $self->{debug};

   $self->{next_time} = int(time);
   $self->reschedule;
   $self->{last_time} = 0;

   return $self;
}



sub run
{
   my $self = shift;

   $self->{logger}->('info', "Running %s",
	$self->{description} || 'unnamed event',
	) if $self->{verbose};

   $self->{macro}->run;
}

sub reschedule
{
   my $self = shift;

   $self->{last_time} = $self->{next_time} || 0;

   my $current = $self->{last_time} || time;
   my $next;

   if (!exists $self->{repeat_type} || $self->{repeat_type} eq 'none')
   {
      return 0;
   }
   elsif ($self->{repeat_type} eq 'day')
   {
      my $new = parsedate(sprintf("today %s", $self->time('today')));

      if ($new <= time || $new <= $current)
      {
         $new = parsedate(sprintf("tomorrow %s", $self->time('tomorrow')));
      }

      # check DOW loop here...
      if (exists $self->{dowmask} && $self->{dowmask} > 0)
      {
         my @newarray = localtime($new);

         while ( ! ( (1 << $newarray[6]) & $self->{dowmask} ) )
         {
            $self->{logger}->('info', "Skipping %s...", strftime("%a %b %e %Y", @newarray))
		if $self->{debug};
            $newarray[3] += 1;		# add one day

            @newarray = localtime(mktime(@newarray));	# normalize

            # find new time on that day...

            my $datestr = strftime("%a %b %e %Y", @newarray);

            my $time = $self->time($datestr);

            $new = parsedate(sprintf("%s %s", $time, $datestr), WHOLE => 1);
            @newarray = localtime($new);
         }

      }

      $next = $new;
   }
   else
   {
      $self->{logger}->('info', "Unsupported repeat type: %s", $self->{repeat_type});
   }


   $self->{next_time} = $next;

   return 1;
}

sub next_time
{
   my $self = shift;

   return $self->{next_time};
}

sub controller
{
   my $self = shift;

   if (@_)
   {
      $self->{macro}->controller(shift);
   }

   return $self->{macro}->controller;
}

sub description
{
   my $self = shift;

   if (@_)
   {
      $self->{description} = shift;
   }

   return $self->{description};
}

sub time
{
   my $self = shift;
   my $date = shift;

   # offsets assumed not to force time across day boundaries...

   my $time;
   my $sign;
   my $offset;

   if ($self->{time} =~ /^\d?\d:\d\d$/)
   {
      $time = $self->{time};
      $offset = 0;
   }
   elsif ($self->{time} =~ /^sunrise(\s*([+-])\s*(\d+))?$/)
   {
      $sign = ($2 eq '-') ? -1 : 1;
      $offset = $3 || 0;
      $time = sun_time(type => 'rise', date => $date,
	latitude => $self->{latitude},
	longitude => $self->{longitude},
	);
   }
   elsif ($self->{time} =~ /^sunset(\s*([+-])\s*(\d+))?$/)
   {
      $sign = ($2 eq '-') ? -1 : 1;
      $offset = $3 || 0;
      $time = sun_time(type => 'set', date => $date,
	latitude => $self->{latitude},
	longitude => $self->{longitude},
	);
   }
   else
   {
      $self->{logger}->('info', "Unknown time string: %s", $self->{time});
      return undef;
   }

   return $time unless $offset;

   my ($hour, $minute) = $time =~ /^(\d?\d):(\d\d)$/;

   $minute += $sign * $offset;

   while ($minute >= 60)
   {
      $minute -= 60;
      $hour++;
   }

   while ($minute < 0)
   {
      $minute += 60;
      $hour--;
   }

   return sprintf("%s:%02s", $hour, $minute);
}


1;

