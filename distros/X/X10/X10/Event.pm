
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Event;

use vars qw(@ISA);

use Storable;

@ISA = qw(Storable);

use strict;

sub new
{
   my $type = shift;

   my $self;

   if (@_ == 1)
   {
      my ($hc, $uc, $func) = &parse_string(shift);

      return undef unless ($hc && $uc && $func);

      $self = {
	house_code => $hc,
	unit_code => $uc,
	func => $func,
	}
   }

   bless $self, $type;

   return $self;
}

sub house_code
{
   my $self = shift;
   return $self->{house_code};
}

sub unit_code
{
   my $self = shift;
   return $self->{unit_code};
}

sub func
{
   my $self = shift;
   return $self->{func};
}

sub as_string
{
   my $self = shift;

   if ($self->unit_code eq 'ALL' || $self->unit_code eq 'LIGHTS')
   {
      return join(' ', $self->house_code, $self->unit_code, $self->func);
   }
   else
   {
      return sprintf("%s%02s %s", $self->house_code, $self->unit_code, $self->func);
   }
}

###

# build a string of words that implement this event
sub compile
{
   my $self = shift;

   my @words = ();

   if ($self->func eq 'ON' || $self->func eq 'OFF')
   {
      if ($self->unit_code eq 'LIGHTS' && $self->func eq 'ON')
      {
         push @words, sprintf("%sL1", $self->house_code);
      }
      elsif ($self->unit_code eq 'ALL' && $self->func eq 'OFF')
      {
         push @words, sprintf("%sA0", $self->house_code);
      }
      elsif ($self->unit_code > 0 && $self->unit_code <= 16)
      {
         push @words,
		sprintf("%s%02s", $self->house_code, $self->unit_code),
		sprintf("%s%2s", $self->house_code, substr($self->func, 0, 2));
      }
      else
      {
         warn sprintf "Unknown command: %s %s %s (%s)",
		$self->house_code, $self->unit_code, $self->func, $_;
      }
   }
   elsif ($self->func eq 'DIM' || $self->func eq 'BRIGHT')
   {
      if ($self->unit_code > 0 && $self->unit_code <= 16)
      {
         push @words,
		sprintf("%s%02s", $self->house_code, $self->unit_code),
                sprintf("%s%2s", $self->house_code, substr($self->func, 0, 2));
      }
      else
      {
         warn sprintf "Unknown command: %s %s %s (%s)",
		$self->house_code, $self->unit_code, $self->func, $_;
      }
   }
   else
   {
      warn sprintf "Unknown command: %s %s %s (%s)",
		$self->house_code, $self->unit_code, $self->func, $_;
   }

   return map {uc} @words;
}


###

sub parse_string
{
   my $string = uc(shift);

   if ( $string =~ /^\s*([a-p])\s*(\d+|all|lights)\s*(on|off|dim|bright)\s*$/i )
   {
      if ( lc($2) eq 'all' && lc($3) eq 'off' )
      {
         return map {uc} ($1, $2, $3);
      }
      elsif ( lc($2) eq 'lights' && lc($3) eq 'on' )
      {
         return map {uc} ($1, $2, $3);
      }
      elsif ( $2 > 0 && $2 <= 16 )
      {
         return (uc($1), $2 * 1, uc($3));
      }
      else
      {
         return ();
      }
   }
   else
   {
      return ();
   }
}


1;

