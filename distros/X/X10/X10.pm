
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10;

use Data::Dumper;
use File::Basename;
use FileHandle;
use POSIX;

use strict;

use X10::Macro;
use X10::MacroProc;
use X10::SchedEvent;
use X10::Scheduler;
use X10::Server;

use vars qw($VERSION);

$VERSION = 0.04;

sub new
{
   my $type = shift;

   my $self = bless { @_ }, $type;

   $self->{verbose} = 1 if $self->{debug};
   $self->{logger} = sub { $self->syslog(@_) };

   unless ($self->{controller_type})
   {
      warn "Interface type must be specified\n";
      return undef;
   }

   my $controller = $self->{controller_type};

   if (eval "require $controller")
   {
      $controller->import;	# just in case
   }
   else
   {
      die "Can't load module for $controller: ", $@;
   }

   $self->{controller} = $controller->new(
	port => $self->{controller_port},
	debug => $self->{debug},
	verbose => $self->{verbose},
	logger => sub { $self->syslog(@_) },
	);

   $self->{controller}->register_listener(
	sub { $self->syslog('info', "Event: %s", $_[0]->as_string) }
	);

   if (exists $self->{devices})
   {
      # load device config
   }

   if (exists $self->{schedulerconfig})
   {
      $self->{scheduler} = new X10::Scheduler(
	configfile => $self->{schedulerconfig},
	controller => $self->{controller},
	debug => $self->{debug},
	verbose => $self->{verbose},
	logger => sub { $self->syslog(@_) },
	latitude => 38.74274,
	longitude => -90.560143,
	);

      unless ($self->{scheduler})
      {
         warn "Problem creating macro processor";
         return undef;
      }

   }

   if (exists $self->{macroconfig})
   {
      $self->{macrop} = new X10::MacroProc(
	configfile => $self->{macroconfig},
	controller => $self->{controller},
	debug => $self->{debug},
	verbose => $self->{verbose},
	logger => sub { $self->syslog(@_) },
	);

      unless ($self->{macrop})
      {
         warn "Problem creating macro processor";
         return undef;
      }

   }

   if (exists $self->{server_port})
   {
      $self->{server} = new X10::Server(
	controller => $self->{controller},
	debug => $self->{debug},
	verbose => $self->{verbose},
	server_port => $self->{server_port},
	logger => sub { $self->syslog(@_) },
	);

      unless ($self->{server})
      {
         warn "Problem creating network server";
         return undef;
      }
   }

   return $self;
}


sub run
{
   my $self = shift;

   # this method plans to never return...

   $self->{running} = 1;

   $SIG{'INT'} = sub { $self->{running} = 0; };
   $SIG{'TERM'} = sub { $self->{running} = 0; };

   $self->syslog('info', "%s service starting", $self->{controller_type});

   my $next_wakeup = 0;

   X10RUNMAINLOOP:
   while ($self->{running})
   {
      $self->{logger}->('info', "Entering mainloop") if $self->{debug};

      my %fdindex;
      foreach my $module (
		grep { exists $self->{$_} } qw(controller server macrop)
		)
      {
         foreach my $fd ($self->{$module}->select_fds)
         {
            $fdindex{$fd} = $self->{$module};
         }
      }

      $self->syslog('info', "All FDs are %s\n", join(', ', keys %fdindex)) if $self->{debug};

      my $rfd = '';
      foreach (keys %fdindex) { vec($rfd, $_, 1) = 1; }

      # done setting up FD array

      # figure out if we have to wake up at a certain time:

      my $timeout = undef;

      if ($self->{scheduler})
      {
         my $next_event_time = $self->{scheduler}->next_event_time;

         if ($next_event_time)
         {
            $timeout = $next_event_time - int(time);
            $timeout = 0 if ($timeout < 0);
         }

         if ( (defined $timeout) && $next_event_time != $next_wakeup)
         {
            $next_wakeup = $next_event_time;
            $self->syslog('info', "Next Scheduled Event: %s (%s seconds away)",
		strftime("%a %b %e %H:%M %Y", localtime($next_event_time)),
		$timeout,
		);
         }

      }

      # done calculating wakeup time

      my $readers;
      my $fdcount = select($readers=$rfd, undef, undef, $timeout);

      if ($fdcount > 0)
      {
         $self->{logger}->('info', "Got %s FDs to handle", $fdcount) if $self->{debug};

         foreach (keys %fdindex)
         {
            if (vec($readers, $_, 1))
            {
               $self->syslog('info', "Processing input on FD %s (%s)\n", $_, $fdindex{$_}) if $self->{debug};
               $fdindex{$_}->handle_input;
            }
         }

      }
      elsif ($fdcount < 0 && $! != 4)	# ignore Interrupted System Call
      {
         $self->{logger}->('info', "Error %d in select(): %s", $!, $!);
      }

      if ($self->{scheduler})
      {
         $self->{scheduler}->run;
      }

   }

   $self->syslog('info', "%s service shutting down", $self->{controller_type});

}

sub syslog
{
   my $self = shift;

   my $level = shift;
   my $format = shift;
   my $message = sprintf($format, @_);

   my $facility = "local5";
   my $tag = sprintf "%s[%s]",
        basename($0, ".pl"),
        $$,
        ;

   if ($self->{debug})
   {
      printf "syslog message: %s\n", $message;
   }
   else
   {
      my $fh = new FileHandle;
      $fh->open("|/usr/bin/logger -p $facility.$level -t $tag");
      $fh->print($message);
      $fh->close;
   }
}



1;

