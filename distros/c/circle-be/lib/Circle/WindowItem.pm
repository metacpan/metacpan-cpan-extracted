#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::WindowItem;

# An abstract role used by objects that should be placed in FE windows or tabs
# Combines the behaviours of:
#   having display events
#   responding to typed lines of text

use strict;
use warnings;

use Carp;

use base qw( Circle::Commandable Circle::Configurable Circle::Loggable );

use Circle::TaggedString;

use Circle::Widget::Box;
use Circle::Widget::Scroller;

sub init_prop_level
{
   return 0;
}

sub bump_level
{
   my $self = shift;
   my ( $newlevel ) = @_;

   return if $self->get_prop_level >= $newlevel;

   $self->set_prop_level( $newlevel );
}

sub method_reset_level
{
   my $self = shift;

   $self->set_prop_level( 0 );
}

sub push_displayevent
{
   my $self = shift;
   my ( $event, $args, %opts ) = @_;

   foreach ( values %$args ) {
      if( !ref $_ ) { 
         next;
      }
      elsif( eval { $_->isa( "Circle::TaggedString" ) } ) {
         $_ = $_->squash;
      }
      else { 
         $_ = "[[TODO: Not sure how to handle $_]]";
      }
   }

   my $time = $opts{time} // time();

   my $scroller = $self->get_widget_scroller;
   $scroller->push_event( $event, $time, $args );

   $self->push_log( $event, $time, $args );
}

sub respond
{
   my $self = shift;
   my ( $text, %opts ) = @_;

   $self->push_displayevent( "response", { text => $text } );
   $self->bump_level( $opts{level} ) if $opts{level};

   return;
}

sub respondwarn
{
   my $self = shift;
   my ( $text, %opts ) = @_;

   $self->push_displayevent( "warning", { text => $text } );
   $self->bump_level( $opts{level} ) if $opts{level};

   return;
}

sub responderr
{
   my $self = shift;
   my ( $text, %opts ) = @_;

   $self->push_displayevent( "error", { text => $text } );
   $self->bump_level( $opts{level} ) if $opts{level};

   return;
}

sub respond_table
{
   my $self = shift;
   my ( $tableref, %opts ) = @_;

   # We need to avoid using join() or sprintf() here, because any of the table
   # cell arguments might be TaggedString objects. The CORE functions won't
   # respect this taggnig.

   my $colsep = exists $opts{colsep} ? delete $opts{colsep} : "  ";

   my $headings = delete $opts{headings};

   my @table = @$tableref;

   my @width;

   foreach my $r ( $headings, @table ) {
      next unless defined $r;

      foreach my $c ( 0 .. $#$r ) {
         my $d = $r->[$c];
         $width[$c] = length $d if !defined $width[$c] or length $d > $width[$c];
      }
   }

   if( $headings ) {
      my $text = Circle::TaggedString->new();
      foreach my $c ( 0 .. $#$headings ) {
         $text->append( $colsep ) if $c > 0;

         my $col = $headings->[$c];
         $text->append_tagged( $col . ( " " x ( $width[$c] - length $col ) ),
                               u => 1 );
      }
      $self->respond( $text, %opts );
   }

   foreach my $tr ( @table ) {
      my $text = Circle::TaggedString->new();
      foreach my $c ( 0 .. $#width ) {
         $text->append( $colsep ) if $c > 0;

         my $col = $tr->[$c];
         $text->append( $col . ( " " x ( $width[$c] - length $col ) ) );
      }
      $self->respond( $text, %opts );
   }
}

sub command_clear
   : Command_description("Clear the scrollback buffer")
   : Command_opt('keeplines=$', desc => "keep this number of lines")
{
   my $self = shift;
   my ( $opts, $cinv ) = @_;

   my $keeplines = $opts->{keeplines} || 0;

   my $scroller = $self->get_widget_scroller;

   my $to_delete = scalar @{ $scroller->get_prop_displayevents } - $keeplines;

   $scroller->shift_prop_displayevents( $to_delete ) if $to_delete > 0;

   return;
}

sub command_dumpevents
   : Command_description("Dump a log of the raw event buffer")
   : Command_arg('filename')
{
   my $self = shift;
   my ( $filename, $cinv ) = @_;

   my $scroller = $self->get_widget_scroller;
   YAML::DumpFile( $filename, $scroller->get_prop_displayevents );

   $cinv->respond( "Dumped event log to $filename" );
   return;
}

###
# Widget
###

sub method_get_widget
{
   my $self = shift;

   return $self->{widget} ||= $self->make_widget();
}

# Useful for debugging and live-development
sub command_rewidget
   : Command_description("Destroy the cached widget tree so it will be recreated")
{
   my $self = shift;

   delete $self->{widget};
   $self->respond( "Destroyed existing widget tree. You will have to restart the frontend now" );

   return;
}

# Subclasses might override this, but we'll provide a default
sub make_widget
{
   my $self = shift;

   my $registry = $self->{registry};

   my $box = $registry->construct(
      "Circle::Widget::Box",
      orientation => "vertical",
   );

   $self->make_widget_pre_scroller( $box ) if $self->can( "make_widget_pre_scroller" );

   $box->add( $self->get_widget_scroller, expand => 1 );

   $box->add( $self->get_widget_statusbar ) if $self->can( "get_widget_statusbar" );

   $box->add( $self->get_widget_commandentry );

   return $box;
}

sub get_widget_scroller
{
   my $self = shift;

   return $self->{widget_displayevents} if defined $self->{widget_displayevents};

   my $registry = $self->{registry};

   my $widget = $registry->construct(
      "Circle::Widget::Scroller",
      scrollback => 1000, # TODO
   );

   return $self->{widget_displayevents} = $widget;
}

sub enumerable_path
{
   my $self = shift;

   if( my $parent = $self->parent ) {
      return $parent->enumerable_path . "/" . $self->enumerable_name;
   }
   else {
      return $self->enumerable_name;
   }
}

0x55AA;
