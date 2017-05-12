
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Scheduler;

# this package implements a scheduler

use Data::Dumper;
use POSIX;

use strict;

sub new
{
   my $type = shift;

   my $self = bless { @_ }, $type;

   return undef unless $self->{controller};

   $self->{logger} ||= sub {
        shift;
        printf(@_);
        print "\n";
        };

   $self->{verbose} = 1 if $self->{debug};

   # $self->{controller}->register_listener($self->event_callback);
   $self->{schedevents} = [];

   if ($self->{configfile})
   {
      my $config = eval { require $self->{configfile} } || die $@;

      foreach (@$config)
      {
         $self->add( new X10::SchedEvent( %$_ ) );
      }
   }

   return $self;
}

###

sub setup
{
   my $self = shift;

   if (@_)
   {
      while (my $key = shift)
      {
      }
   }

   return $self->{schedevents};
}

sub add
{
   my $self = shift;
   my $se = shift;

   return undef unless ($se && $se->isa('X10::SchedEvent'));

   $se->controller($self->{controller});
   $se->{logger} = $self->{logger};
   $se->{latitude} = $self->{latitude} || 38.74274;
   $se->{longitude} = $self->{longitude} || -90.560143;

   $self->{logger}->('info', "Queueing %s for %s",
	$se->description || 'unnamed event',
	strftime("%a %b %e %H:%M %Y", localtime($se->next_time)),
	);

   push @{$self->{schedevents}}, $se;

   @{$self->{schedevents}} =
	sort { $a->next_time <=> $b->next_time }
	@{$self->{schedevents}};

   return 1;
}

sub next_event_time
{
   my $self = shift;

   return 0 unless (@{$self->{schedevents}} > 0);

   return $self->{schedevents}->[0]->next_time;
}

sub run
{
   my $self = shift;

   while ( @{$self->{schedevents}}
	&& $self->{schedevents}->[0]->next_time <= (int(time) + 30) )
   {
      my $se = shift @{$self->{schedevents}};

      $se->run;

      if ($se->reschedule)
      {
         $self->add($se);
      }
      else
      {
      }
   }
}

# nothing to do with events
sub event_callback
{
   my $self = shift;
   return sub {  };
}

# no fds to deal with
sub select_fds
{
   return ();
}


1;

