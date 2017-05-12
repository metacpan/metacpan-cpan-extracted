
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::EventList;

use vars qw(@ISA);

use Storable;

@ISA = qw(Storable);

use strict;

sub new
{
   my $type = shift;

   my $self = bless { list => [] }, $type;

   foreach (@_)
   {
      if (ref $_ eq 'X10::Event')
      {
         push @{$self->{list}}, $_;
      }
      elsif (ref $_ eq 'X10::EventList')
      {
         push @{$self->{list}}, $_->list;
      }
      elsif (ref $_ eq '')
      {
         push @{$self->{list}}, new X10::Event($_);
      }
      else
      {
         warn "Can't deal with a ", ref $_;
      }
   }

   @{$self->{list}} = grep { $_ } @{$self->{list}};

   return undef unless @{$self->{list}};

   return $self;
}

sub as_string
{
   my $self = shift;

   join(', ', map { $_->as_string } @{$self->{list}});
}

sub list
{
   my $self = shift;
   @{$self->{list}};
}

###

# build a string of words that implement this event
sub compile
{
   my $self = shift;

   map { $_->compile } @{$self->{list}};
}


###


1;

