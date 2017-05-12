#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2012 -- leonerd@leonerd.org.uk

package Circle::Commandable;

use strict;
use warnings;

use Carp;

use Attribute::Storage 0.06 qw( get_subattr get_subattrs );

use Circle::Command;
use Circle::CommandInvocation;

use Circle::Widget::Entry;

#############################################
### Attribute handlers for command_* subs ###
#############################################

sub Command_description :ATTR(CODE)
{
   my $class = shift;
   my ( $text ) = @_;

   my ( $brief, $detail ) = split( m/\n/, $text, 2 );

   return [ $brief, $detail ];
}

sub Command_arg :ATTR(CODE,MULTI)
{
   my $class = shift;
   my ( $args, $name, %spec ) = @_;

   # Some things are only allowed on the last argument. Check none of these
   # apply to the previous one
   my $prev = $args ? $args->[-1] : undef;

   if( $prev ) {
      $prev->{eatall}  and croak "Cannot have another argument after an eatall";
      $prev->{collect} and croak "Cannot have another argument after a collect";
      $prev->{trail}   and croak "Cannot have another argument after a trail";
   }

   my $optional = $name =~ s/\?$//; # No error if this is missing

   my %arg = (
      name     => uc $name,
      optional => $optional,
      eatall   => delete $spec{eatall},  # This argument consumes all the remaining text in one string
      collect  => delete $spec{collect}, # This argument collects all the non-option tokens in an ARRAY ref
   );

   $arg{eatall} and $arg{collect} and croak "Cannot eatall and collect";

   keys %spec and croak "Unrecognised argument specification keys: ".join( ", ", keys %spec );

   my $trail = 0;
   if( $name eq "..." ) {
      $arg{trail} = 1;
   }
   else {
      $name =~ m/\W/ and croak "Cannot use $name as an argument name";
   }

   push @$args, \%arg;

   return $args;
}

sub Command_opt :ATTR(CODE,MULTI)
{
   my $class = shift;
   my ( $opts, $name, %spec ) = @_;

   my %opt = (
      desc => delete $spec{desc},
   );

   keys %spec and croak "Unrecognised option specification keys: ".join( ", ", keys %spec );

   $name =~ s/=(.*)$// or croak "Cannot recognise $name as an option spec";
   $opt{type} = $1;

   $opt{type} =~ m/^[\$\+]$/ or croak "Cannot recognise $opt{type} as an option type";

   $opts->{$name} = \%opt;

   return $opts;
}

sub Command_subof :ATTR(CODE)
{
   my $class = shift;
   my ( $parent ) = @_;

   return $parent;
}

sub Command_default :ATTR(CODE)
{
   return 1; # Just a boolean
}

sub do_command
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $cmd = $cinv->pull_token;

   my $command = undef;
   my %commands = Circle::Command->root_commands( $cinv );

   while( keys %commands and $cmd ||= $cinv->pull_token ) {
      unless( exists $commands{$cmd} ) {
         $cinv->responderr( $command ? $command->name . " has no sub command $cmd"
                                     : "No such command $cmd" );
         return;
      }

      $command = $commands{$cmd};
      %commands = $command->sub_commands( $cinv );

      undef $cmd;
   }

   while( keys %commands ) {
      my $subcmd = $command->default_sub( $cinv );

      if( !$subcmd ) {
         # No default subcommand - issue help on $command instead
         my $helpinv = $cinv->nest( "help " . $command->name );
         return $self->do_command( $helpinv );
      }

      $command = $subcmd;
      %commands = $command->sub_commands( $cinv );
   }

   my $cname = $command->name;

   my @args;
   my %opts;

   my @argspec = $command->args;
   my $optspec = $command->opts;

   my $argindex = 0;

   my $no_more_opts;
   while( length $cinv->peek_remaining ) {
      if( $cinv->peek_token eq "--" ) {
         $cinv->pull_token;
         $no_more_opts++;
         next;
      }

      if( !$no_more_opts and $cinv->peek_remaining =~ m/^-/ ) {
         # An option
         my $optname = $cinv->pull_token;
         $optname =~ s/^-//;

         $optspec and exists $optspec->{$optname} or 
            return $cinv->responderr( "$cname: unrecognised option $optname" );

         my $optvalue;

         if( $optspec->{$optname}{type} eq '$' ) {
            $optvalue = $cinv->pull_token;
            defined $optvalue or
               return $cinv->responderr( "$cname: option $optname require a value" );
         }
         else {
            $optvalue = 1;
         }

         $opts{$optname} = $optvalue;
      }
      else {
         return $cinv->responderr( "$cname: Too many arguments" ) if !@argspec or $argindex >= @argspec;

         my $a = $argspec[$argindex];

         if( $a->{eatall} ) {
            push @args, $cinv->peek_remaining;
            $argindex++;
            last;
         }
         elsif( $a->{collect} ) {
            # If this is the first one, $args[-1] won't be an ARRAY ref
            push @args, [] unless ref $args[-1];
            push @{ $args[-1] }, $cinv->pull_token;
         }
         elsif( $a->{trail} ) {
            last;
         }
         else {
            push @args, $cinv->pull_token;
            $argindex++;
         }
      }
   }

   while( $argindex < @argspec ) {
      my $a = $argspec[$argindex++];

      if( $a->{collect} ) {
         push @args, [] unless ref $args[-1];
         last;
      }
      elsif( $a->{trail} ) {
         last;
      }

      $a->{optional} or 
         return $cinv->responderr( "$cname: expected $a->{name}" );

      push @args, undef;
   }

   push @args, \%opts if $optspec;

   push @args, $cinv;

   my @response = eval { $command->invoke( @args ) };
   if( $@ ) {
      my $text = $@; chomp $text;
      $cinv->responderr( $text );
   }
   else {
      $cinv->respond( $_ ) foreach @response;
   }
}

sub command_help
   : Command_description("Display help on a command")
   : Command_arg('command?')
   : Command_arg('...')
{
   my $self = shift;
   my ( $cmd, $cinv ) = @_;

   my $command = undef;
   my %commands = Circle::Command->root_commands( $cinv );

   if( !defined $cmd ) {
      my $class = ref $self || $self;
      $cinv->respond( "Available commands for $class:" );
   }

   while( ( $cmd ||= $cinv->pull_token ) ) {
      unless( exists $commands{$cmd} ) {
         $cinv->responderr( $command ? $command->name . " has no sub command $cmd"
                                     : "No such command $cmd" );
         return;
      }

      $command = $commands{$cmd};
      %commands = $command->sub_commands( $cinv );

      undef $cmd;
   }

   if( $command ) {
      $cinv->respond( "/" . $command->name . " - " . $command->desc );
   }

   if( keys %commands ) {
      $cinv->respond( "Usage: " . $command->name . " SUBCMD ..." ) if $command;

      my @table;
      foreach my $sub ( map { $commands{$_} } sort keys %commands ) {
         my $subname;
         # bold function name if it's default
         if( $sub->is_default ) {
            $subname = Circle::TaggedString->new( " /" . $sub->name );
            $subname->apply_tag( 0, $subname->length, b => 1 );
         }
         else {
            $subname = " /" . $sub->name;
         }

         push @table, [ $subname, $sub->desc ];
      }

      $cinv->respond_table( \@table, colsep => " - ", headings => [ "Command", "Description" ] );

      return;
   }

   my @argdesc;
   foreach my $a ( $command->args ) {
      my $name = $a->{name};
      $name .= "..."    if $a->{eatall};
      $name .= "+"      if $a->{collect};
      $name = "[$name]" if $a->{optional};
      push @argdesc, $name;
   }

   $cinv->respond( "Usage: " . join( " ", $command->name, @argdesc ) );

   if( my $opts = $command->opts ) {
      $cinv->respond( "Options:" );

      my @table;

      foreach my $opt ( sort keys %$opts ) {
         my $opttype = $opts->{$opt}{type};
         my $desc = defined $opts->{$opt}{desc} ? $opts->{$opt}{desc} : "";

         push @table, [ "  -$opt" . ( $opttype eq '$' ? " VALUE" : "" ), $desc ];
      }

      $cinv->respond_table( \@table, headings => [ "Option", "Description" ] );
   }

   if( my $detail = $command->detail ) {
      $cinv->respond( "" );
      $cinv->respond( $_ ) for split( m/\n/, $detail );
   }

   return;
}

sub method_do_command
{
   my $self = shift;
   my ( $ctx, $command ) = @_;

   my $cinv = Circle::CommandInvocation->new( $command, $ctx->stream, $self );
   $self->do_command( $cinv );
}

###
# Widget
###

sub get_widget_commandentry
{
   my $self = shift;

   return $self->{widget_commandentry} if defined $self->{widget_commandentry};

   my $registry = $self->{registry};

   my $widget = $registry->construct(
      "Circle::Widget::Entry",
      autoclear => 1,
      focussed => 1,
      history => 100, # TODO
      on_enter => sub {
         my ( $text, $ctx ) = @_;

         if( $text =~ m{^/} ) {
            substr( $text, 0, 1 ) = "";

            my $cinv = Circle::CommandInvocation->new( $text, $ctx->stream, $self );
            $self->do_command( $cinv );
         }
         elsif( $self->can( "enter_text" ) ) {
            $self->enter_text( $text );
         }
         else {
            $self->responderr( "Cannot enter raw text here" );
         }
      },
   );

   return $self->{widget_commandentry} = $widget;
}

0x55AA;
