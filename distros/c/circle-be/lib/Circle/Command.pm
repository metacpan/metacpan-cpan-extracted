#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::Command;

use strict;
use warnings;

use Attribute::Storage qw( get_subattrs get_subattr find_subs_with_attr );
require mro;

sub _find_commands
{
   my ( $obj, $cinv, $containedby ) = @_;

   my @ret;
   my %commands;

   while( $obj ) {
      my %subs = find_subs_with_attr( mro::get_linear_isa( ref $obj ), "Command_description",
         matching => qr/^command_/,
      );

      foreach my $name ( keys %subs ) {
         ( my $commandname = $name ) =~ s/^command_//;
         my $cv = $subs{$name};

         next if $commands{$commandname};

         my $subof = get_subattr( $cv, "Command_subof" );
         next if  $containedby and !$subof or
                 !$containedby and  $subof or
                  $containedby and $subof and $containedby ne $subof;

         my $attrs = get_subattrs( $cv );

         $commands{$commandname} = 1;
         push @ret, __PACKAGE__->new( %$attrs,
            name => $commandname,
            obj  => $obj,
            cv   => $cv,
         );
      }

      # Collect in parent too
      $obj = $obj->can( "commandable_parent" ) && $obj->commandable_parent( $cinv );
   }

   return @ret;
}

sub root_commands
{
   my $class = shift;
   my ( $cinv ) = @_;

   return map { $_->name => $_ } _find_commands( $cinv->invocant, $cinv, undef );
}

# Object stuff

sub new
{
   my $class = shift;
   my %attrs = @_;

   $attrs{name} =~ s/_/ /g;

   return bless \%attrs, $class;
}

sub sub_commands
{
   my $self = shift;
   my ( $cinv ) = @_;

   return map { $_->shortname => $_ } _find_commands( $cinv->invocant, $cinv, $self->name );
}

sub name
{
   my $self = shift; return $self->{name};
}

sub shortname
{
   my $self = shift;
   ( split m/ /, $self->name )[-1];
}

sub is_default
{
   my $self = shift; return $self->{Command_default};
}

sub desc
{
   my $self = shift; return $self->{Command_description}[0] || "[no description]";
}

sub detail
{
   my $self = shift; return $self->{Command_description}[1];
}

sub args
{
   my $self = shift; 
   return unless $self->{Command_arg};
   return @{ $self->{Command_arg} };
}

sub opts
{
   my $self = shift;
   return $self->{Command_opt};
}

sub default_sub
{
   my $self = shift;
   my ( $cinv ) = @_;

   my %subs = $self->sub_commands( $cinv );
   my @defaults = grep { $_->is_default } values %subs;

   return $defaults[0] if @defaults == 1; # Only if it's unique
   return;
}

sub invoke
{
   my $self = shift; $self->{cv}->( $self->{obj}, @_ );
}

0x55AA;
