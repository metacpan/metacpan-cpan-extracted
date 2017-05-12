
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Macro;

use strict;

use X10::Event;


sub new
{
   my $type = shift;

   my $self = bless { @_ }, $type;

   return $self;
}


sub run
{
   my $self = shift;

   return undef unless $self->{controller};

   # send a list of events (specified by string)
   if (exists $self->{events})
   {
      $self->{controller}->send(
	map { new X10::Event($_) } @{$self->{events}}
	);
   }
   # send a list of events returned by a perl sub
   elsif (exists $self->{perleval})
   {
      $self->{controller}->send($self->{perleval}->());
   }
   # run a perl sub
   elsif (exists $self->{perlsub})
   {
      $self->{perlsub}->();
   }
   else
   {
      return undef;
   }

   return 1;
}

sub controller
{
   my $self = shift;

   if (@_)
   {
      $self->{controller} = shift;
   }

   return $self->{controller};
}

sub description
{
   my $self = shift;
   return $self->{description};
}



1;

