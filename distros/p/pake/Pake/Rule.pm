package Pake::Rule;

use strict;
use warnings;

sub new{
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $pattern = shift;
   my $source = shift;
   my $code = sub {};
   $code = shift if ref($_[0]) eq "CODE";

   my $self  = {};

   $self->{"pattern"} = $pattern;
   $self->{"code"} = $code;
   $self->{"source"} = $source;

   bless ($self, $class);
   Pake::Application::add_rule($self);
   return $self;   
}

1;
__END__

=head1 NAME

Pake::Rule

=head1 SYNOPSIS

Right now Rules should not be extended.

=head1 Description

Rule, executes if the the specified task does not exists and the rule matches the task name

=cut
