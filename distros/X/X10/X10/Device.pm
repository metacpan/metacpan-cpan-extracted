
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Device;

sub new
{
   my $type = shift;

   my $self = bless { @_ }, $type;

   $self->{house_code} = $self->{controller}->{house_code} unless $self->{house_code};

   return $self;
}


### manipulating the device:

sub on
{
   my $self = shift;
   return 0 unless $self->{controller};
   $self->{controller}->on($self);
}

sub off
{
   my $self = shift;
   return 0 unless $self->{controller};
   $self->{controller}->off($self);
}

sub dim
{
   my $self = shift;
   return 0 unless $self->{controller};
   $self->{controller}->dim($self);
}

sub bright
{
   my $self = shift;
   return 0 unless $self->{controller};
   $self->{controller}->bright($self);
}

### access methods

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

sub address
{
   my $self = shift;
   return sprintf("%s%02s", $self->house_code, $self->unit_code);
}

1;

