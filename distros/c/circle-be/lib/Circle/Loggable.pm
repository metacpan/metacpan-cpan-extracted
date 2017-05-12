#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Circle::Loggable;

use strict;
use warnings;
use base qw( Circle::Commandable Circle::Configurable );

use File::Basename qw( dirname );
use File::Path qw( make_path );
use POSIX qw( strftime mktime );

__PACKAGE__->APPLY_Inheritable_Setting( log_enabled =>
   description => "Enable logging of events",
   type        => 'bool',
);

__PACKAGE__->APPLY_Inheritable_Setting( log_path =>
   description => "Path template for log file name",
   type        => 'str',
);

use Struct::Dumb qw( readonly_struct );

# Data about the log file itself
readonly_struct LogId => [qw(
   path time_start time_until itempath line_timestamp_fmt
)];

# Data about logging from a particular item
readonly_struct LogCtx => [qw(
   path_residue
)];

our $NO_LOG = 0;

sub push_log
{
   my $self = shift;
   my ( $event, $time, $args ) = @_;

   return unless $self->setting_log_enabled;
   return if $NO_LOG;

   # Best-effort
   eval {
      my $logger = $self->logger( $time );

      my $ctx = $self->{logctx};

      $logger->log( $ctx, $time, $event, $args );
      1;
   } and return;

   {
      local $NO_LOG = 1;
      warn "Unable to log - $@";
   }
}

my %time_format_to_idx = (
   Y => 5,
   m => 4,
   d => 3,
   H => 2,
   M => 1,
   S => 0,
);

# Returns a LogId and a LogCtx
sub split_logpath
{
   my $self = shift;
   my ( $time ) = @_;

   my @pcs = split m{/}, $self->enumerable_path;
   shift @pcs; # trim leading /
   @pcs or @pcs = ( "Global" );
   my $path_used = 0;
   my %ts_used = map { $_ => 0 } qw( Y m d H M );

   my @timestamp = localtime $time;

   my %formats = (
      # Specific kinds of time format so we can track the granulity being used
      ( map {
         my $format = $_;
         $format => sub {
            $ts_used{$format}++;
            strftime( "%$format", @timestamp )
         };
        } qw( Y m d H M ) ),
      P => sub {
         my ( $limit ) = @_;
         defined $limit or $limit = @pcs;

         my $path_lower = $path_used;
         my $path_upper = $limit;

         $path_used = $path_upper if $path_upper > $path_used;

         return join '/', map { $_ // "" } @pcs[$path_lower..$path_upper-1];
      },
   );

   my $path = $self->setting_log_path;
   $path =~ s<%(?:{([^}]*)})?(.)>
             {exists $formats{$2} ? $formats{$2}->($1)
                                  : die "Unrecognised escape '%$2"}eg;

   # Reset to zero all the fields that aren't used
   $ts_used{$_} or $timestamp[$time_format_to_idx{$_}] = 0 for qw( Y m d H M S );
   $timestamp[3] or $timestamp[3] = 1; # mday is 1-based

   my $time_start = strftime( "%Y/%m/%d %H:%M:%S", @timestamp );

   # Increment the last timestamp field before a field not used in the file
   # path
   $ts_used{$_} or $timestamp[$time_format_to_idx{$_}+1]++, last for qw( m d H M S );
   my $time_until = mktime @timestamp;

   my $time_fmt_day = join "/", map { $ts_used{$_} ? () : ( "\%$_" ) } qw( Y m d );
   my $time_fmt_sec = join ":", map { $ts_used{$_} ? () : ( "\%$_" ) } qw( H M S );

   my $logid = LogId(
      $path,
      $time_start,
      $time_until,
      join( '/', grep { defined } @pcs[0..$path_used-1] ),
      join( " ", grep { length } $time_fmt_day, $time_fmt_sec ),
   );

   my $logctx = LogCtx(
      join( '/', grep { defined } @pcs[$path_used..$#pcs] ),
   );

   return ( $logid, $logctx );
}

our %LOGGER_FOR_PATH;

sub logger
{
   my $self = shift;
   my ( $time ) = @_;

   my ( $logid, $logctx ) = $self->split_logpath( $time );
   my $path = $logid->path;

   if( defined $self->{logpath} and $self->{logpath} ne $path ) {
      $self->close_logger;
   }
   if( defined $self->{loguntil} and $time >= $self->{loguntil} ) {
      $self->close_logger;
   }

   my $logger = $LOGGER_FOR_PATH{$path} ||= do {
      my $dir = dirname( $path );
      unless( -d $dir ) {
         make_path( $dir, { mode => 0700 } ) or die "Cannot mkdir $dir - $!";
      }

      Circle::Loggable::Backend::CircleLog->open( $logid );
   };

   if( !defined $self->{logpath} ) {
      $self->{logpath} = $path;
      $self->{loguntil} = $logid->time_until;
      $logger->hold_ref;

      # TODO set up a timer to expire and close the log at that time
   }

   $self->{logctx} = $logctx;

   return $logger;
}

sub close_logger
{
   my $self = shift;

   my $logger = $LOGGER_FOR_PATH{$self->{logpath} // ""} or return;

   $logger->drop_ref;
   if( !$logger->refcount ) {
      delete $LOGGER_FOR_PATH{$self->{logpath}};
      $logger->close;
   }

   undef $self->{logpath};
}

sub command_log
   : Command_description("Configure logging")
{
}

sub command_log_info
   : Command_description("Show information about logging")
   : Command_subof('log')
   : Command_default()
{
   my $self = shift;
   my ( $cinv ) = @_;

   if( $self->_setting_log_enabled_inherits ) {
      $cinv->respond( "Logging is inherited (currently " . ( $self->setting_log_enabled ? "enabled" : "disabled" ) . ")" );
   }
   elsif( $self->setting_log_enabled ) {
      $cinv->respond( "Logging is directly enabled" );
   }
   else {
      $cinv->respond( "Logging is directly disabled" );
   }

   if( $self->setting_log_enabled ) {
      my ( $logid, $logctx ) = $self->split_logpath( time );

      $cinv->respond( "Logging to path " . $logid->path );
      $cinv->respond( "Timestamp starts " . $logid->time_start );
      $cinv->respond( "Timestamp until " . strftime( "%Y/%m/%d %H:%M:%S", localtime $logid->time_until ) );
      $cinv->respond( "Line timestamp is " . $logid->line_timestamp_fmt );

      $cinv->respond( "Path residue is " . $logctx->path_residue );
   }

   return;
}

sub command_log_enable
   : Command_description("Enable logging of this item and its children")
   : Command_subof('log')
{
   my $self = shift;
   my ( $cinv ) = @_;

   $self->setting_log_enabled( 1 );
   $cinv->respond( "Logging enabled" );
   return;
}

sub command_log_disable
   : Command_description("Disable logging of this item and its children")
   : Command_subof('log')
{
   my $self = shift;
   my ( $cinv ) = @_;

   $self->setting_log_enabled( 0 );
   $cinv->respond( "Logging disabled" );
   return;
}

sub command_log_inherit
   : Command_description("Inherit log enabled state from parent")
   : Command_subof('log')
{
   my $self = shift;
   my ( $cinv ) = @_;

   $self->setting_log_enabled( undef );
   $cinv->respond( "Logging inherited (currently " . $self->setting_log_enabled ? "enabled" : "disabled" );
   return;
}

sub command_log_rotate
   : Command_description("Rotate the current log file handle")
   : Command_subof('log')
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $path;
   my $n_suffix = 1;
   $n_suffix++ while -f ( $path = "$self->{logpath}.$n_suffix" );

   unless( rename( $self->{logpath}, $path ) ) {
      $cinv->responderr( "Cannot rename $self->{logpath} to $path - $!" );
      return;
   }

   $cinv->respond( "Log file rotated to $path" );

   $self->{logger}->close;
   undef $self->{logger};

   return;
}

package # hide
   Circle::Loggable::Backend::CircleLog;

use POSIX qw( strftime );

sub open
{
   my $class = shift;
   my ( $id ) = @_;

   my $path = $id->path;
   open my $fh, ">>", $path or die "Cannot open event log $path - $!";
   chmod $fh, 0600;

   $fh->binmode( ":encoding(UTF-8)" );
   $fh->autoflush;

   $fh->print( "!LOG START=\"${\$id->time_start}\" ITEMS=\"${\$id->itempath}\" TIMESTAMP_FMT=\"${\$id->line_timestamp_fmt}\"\n" );

   return bless {
      fh => $fh,
      refcount => 0,
      id => $id,
   }, $class;
}

sub refcount { shift->{refcount} }
sub hold_ref { shift->{refcount}++ }
sub drop_ref { shift->{refcount}-- }

sub close
{
   my $self = shift;
   warn "Closing $self with references open" if $self->{refcount};

   close $self->{fh};
}

sub log
{
   my $self = shift;
   my ( $ctx, $time, $event, $args ) = @_;

   my $line = strftime( $self->{id}->line_timestamp_fmt, localtime $time );
   $line .= " ".$ctx->path_residue if length $ctx->path_residue;
   $line .= " $event";
   $line .= " ".$self->encode( $args );
   $line .= "\n";

   $self->{fh}->print( $line );
}

## This should output a valid YAML encoding of a data tree, on a single line
#  using flow-style mappings and sequences
#  Similar to JSON except without quoted keys

sub encode
{
   my $self = shift;
   my ( $args ) = @_;

   if( !ref $args ) {
      my $str = "$args";
      $str =~ s/(["\\])/\\$1/g;
      $str =~ s/\n/\\n/g;
      $str =~ s/\t/\\t/g;
      $str =~ s/([\x00-\x1f\x80-\x9f])/sprintf "\\x%02x", ord $1/eg;
      return qq("$str");
   }
   elsif( ref $args eq "HASH" ) {
      return "{" . join( ", ", map {
         "$_: ".$self->encode( $args->{$_} )
       } sort keys %$args ) . "}";
   }
   elsif( ref $args eq "ARRAY" ) {
      return "[" . join( ", ", map {
         $self->encode( $args->[$_] )
      } 0 .. $#$args ) . "]";
   }
   else {
      return "$args";
   }
}

0x55AA;
