
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::MacroProc;

# this package implements a macro processor using an event callback mechanism

use Data::Dumper;

use strict;

use X10::Event;

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

   $self->{controller}->register_listener($self->event_callback);
   $self->{macros} = {};

   if ($self->{configfile})
   {
      my $config = eval { require $self->{configfile} } || die $@;

      foreach (keys %$config)
      {
         $self->add( $_ => $config->{$_} );
      }
   }

   return $self;
}

###

sub add
{
   my $self = shift;
   my ($key, $macro) = @_;

   my $nkey = X10::Event->new($key)->as_string;

   $self->{logger}->('info', "Replacing old macro for %s", $nkey)
	if exists $self->{macros}->{$nkey};

   $self->{macros}->{$nkey} = $macro;
   $self->{macros}->{$nkey}->controller($self->{controller});
}

sub setup
{
   my $self = shift;

   if (@_)
   {
      while (my $key = shift)
      {
         my $nkey = X10::Event->new($key)->as_string;

         if ($nkey)
         {
            $self->{macros}->{$nkey} = shift;
            $self->{macros}->{$nkey}->controller($self->{controller});
         }
         else
         {
            $self->{logger}->('info', "Throwing away macro for ", $key);
            shift;
         }
      }

   }

   return $self->{macros};
}

sub event_callback
{
   my $self = shift;
   return sub { $self->handle_event(shift) };
}

sub handle_event
{
   my $self = shift;
   my $event = shift;

   if (exists $self->{macros}->{$event->as_string})
   {
      $self->{logger}->('info', "Macro: %s",
	$self->{macros}->{$event->as_string}->description || $event->as_string
	);

      $self->{macros}->{$event->as_string}->run
	|| $self->{logger}->('info', "Problem running macro: %s",
		$self->{macros}->{$event->as_string}->description
		|| $event->as_string);
   }
   elsif ($self->{debug})
   {
      $self->{logger}->('info', "No macro for %s", $event->as_string);
   }

}

sub select_fds
{
   return ();
}


1;

