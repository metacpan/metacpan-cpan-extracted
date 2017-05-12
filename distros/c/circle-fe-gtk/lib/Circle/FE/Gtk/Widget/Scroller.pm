#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::FE::Gtk::Widget::Scroller;

use strict;
use warnings;

use constant type => "Scroller";

use Glib qw( TRUE FALSE );

use POSIX qw( strftime );
use Text::Balanced qw( extract_bracketed );

# The perl bindings don't make this very easy
use constant PANGO_WEIGHT_BOLD => 700;

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $widget = Gtk2::ScrolledWindow->new();
   $widget->set_policy( 'never', 'always' );

   my $textview = Gtk2::TextView->new();
   $widget->add( $textview );

   $textview->set_editable( FALSE );
   $textview->set_cursor_visible( FALSE );
   $textview->set_wrap_mode( 'word-char' );

   $textview->set_indent( -50 );

   $textview->modify_font( $tab->get_font );
   $textview->modify_base( normal => $tab->get_theme_colour( "bgcolor" ) );
   $textview->modify_text( normal => $tab->get_theme_colour( "textcolor" ) );

   my $buffer = $textview->get_buffer;

   my $self = bless {
      tab => $tab,
      textview => $textview,
      textbuffer => $buffer,
      scrollwindow => $widget,
      last_datestamp => "",
      linestarts => [],
   };

   $tab->{scroller} = $self;

   $self->{start_para_mark} = $buffer->create_mark( "start_para", $buffer->get_end_iter, TRUE );
   my $endmark = $buffer->create_mark( "end", $buffer->get_end_iter, FALSE );

   $obj->watch_property(
      property => "displayevents",
      on_set => sub {
         $textview->set_buffer( Gtk2::TextBuffer->new( $buffer->get_tag_table ) );
         $self->append_event( $_ ) for @{ $_[0] };
         $textview->set_buffer( $buffer );
         $textview->scroll_mark_onscreen( $endmark );
      },
      on_push => sub {
         my $at_end = $self->at_end;
         $self->append_event( $_ ) for @_;
         $textview->scroll_mark_onscreen( $endmark ) if $at_end;
      },
      on_shift => sub {
         $self->shift_events( $_[0] );
      },
      on_splice => sub { 'TODO' },
      want_initial => 1,
   );

   return $widget;
}

# Helper "methods"

sub apply_format_colour
{
   my $self = shift;
   my ( $tags, $attr, $colour ) = @_;

   @$tags = grep { !$_->get( "$attr-set" ) } @$tags;

   push @$tags, $self->{$attr . "tags"}->{$colour} ||= $self->{textbuffer}->create_tag( undef,
      $attr => $colour,
   );
}

my %format_attrs = (
   bold      => [ weight => PANGO_WEIGHT_BOLD ],
   italic    => [ style => 'italic' ],
   underline => [ underline => 'single' ],
);

sub apply_format_simple
{
   my $self = shift;
   my ( $tags, $name ) = @_;

   my ( $attr, $value ) = @{ $format_attrs{$name} };

   @$tags = grep { !$_->get( "$attr-set" ) } @$tags;

   push @$tags, $self->{simpletags}->{$name} ||= $self->{textbuffer}->create_tag( undef,
      $attr => $value,
   );
}

sub apply_indent
{
   my $self = shift;

   my $buffer = $self->{textbuffer};
   
   my $end = $buffer->get_end_iter;
   my $start_para = $buffer->get_iter_at_mark( $self->{start_para_mark} );

   my $text = $buffer->get_text( $start_para, $end, FALSE );

   my $layout = Gtk2::Pango::Layout->new( $self->{textview}->get_pango_context );
   $layout->set_text( $text );
   my ( $ink_rect, $logical_rect ) = $layout->get_pixel_extents;

   my $width = $logical_rect->{width};

   my $tag = $buffer->create_tag( undef, indent => -$width );
   $buffer->apply_tag( $tag, $start_para, $end );
}

sub _append_formatted_inner
{
   my $self = shift;
   my ( $format, $args, $enditer, $buffer, $tags ) = @_;

   my $tab = $self->{tab};

   while( length $format ) {
      if( $format =~ s/^\$(\w+)// ) {
         my $val = exists $args->{$1} ? $args->{$1} : "<No such variable $1>";
         defined $val or $val = "<Variable $1 is not defined>";

         my @parts = ref $val eq "ARRAY" ? @$val : ( $val );

         foreach my $part ( @parts ) {
            my ( $text, %format ) = ref $part eq "ARRAY" ? @$part : ( $part );

            my @parttags = @$tags;

            foreach my $a ( keys %format ) {
               $self->apply_format_colour( \@parttags, foreground => $tab->translate_theme_colour( $format{fg} ) ), next if $a eq "fg";
               $self->apply_format_colour( \@parttags, background => $tab->translate_theme_colour( $format{bg} ) ), next if $a eq "bg";

               $self->apply_format_simple( \@parttags, 'bold'      ), next if $a eq "b"; 
               $self->apply_format_simple( \@parttags, 'italic'    ), next if $a eq "i";
               $self->apply_format_simple( \@parttags, 'underline' ), next if $a eq "u";

               $self->apply_indent, next if $a eq "indent";

               print STDERR "Unhandled BE attr $a\n";
            }

            $buffer->insert_with_tags( $enditer, $text, @parttags );
         }
      }
      elsif( $format =~ m/^\{/ ) {
         my $piece = extract_bracketed( $format, "{}" );
         s/^{//, s/}$// for $piece;

         if( $piece =~ m/ / ) {
            my ( $code, $content ) = split( m/ /, $piece, 2 );

            my @newtags = @$tags;
            my ( $type, $arg ) = split( m/:/, $code, 2 );

            # Fake switch-alike
            for my $a ( $type ) {
               $self->apply_format_colour( \@newtags, foreground => $arg ), next if $a eq "fg";
               $self->apply_format_colour( \@newtags, background => $arg ), next if $a eq "bg";

               $self->apply_format_simple( \@newtags, 'bold'      ), next if $a eq "b";
               $self->apply_format_simple( \@newtags, 'italic'    ), next if $a eq "i";
               $self->apply_format_simple( \@newtags, 'underline' ), next if $a eq "u";

               $self->apply_indent, next if $a eq "indent";

               print STDERR "Unrecognised format code $a\n";
            }

            $self->_append_formatted_inner( $content, $args, $enditer, $buffer, \@newtags );
         }
         else {
            $self->_append_formatted_inner( $piece, $args, $enditer, $buffer, $tags );
         }
      }
      else {
         $format =~ s/^([^\$\{]+)//;
         my $val = $1;
         $buffer->insert_with_tags( $enditer, $val, @$tags );
      }
   }
}

sub append_formatted
{
   my $self = shift;
   my ( $format, $args ) = @_;

   my $buffer = $self->{textbuffer};
   my $enditer = $buffer->get_end_iter;

   $buffer->move_mark( $self->{start_para_mark}, $buffer->get_end_iter );

   $self->_append_formatted_inner( $format, $args, $enditer, $buffer, [] );

}

sub append_event
{
   my $self = shift;
   my ( $ev ) = @_;

   my ( $event, $time, $args ) = @$ev;

   my $tab = $self->{tab};

   my @time = localtime( $time );

   my $datestamp = strftime( $tab->get_theme_var( "datestamp" ), @time );
   my $timestamp = strftime( $tab->get_theme_var( "timestamp" ), @time );

   my $buffer = $self->{textbuffer};

   if( $buffer->get_line_count > 1 or $buffer->get_text( $buffer->get_start_iter, $buffer->get_end_iter, TRUE ) ne "" ) {
      $buffer->insert( $buffer->get_end_iter, "\n" );
   }

   push @{ $self->{linestarts} }, $buffer->create_mark( undef, $buffer->get_end_iter, TRUE );

   if( $datestamp ne $self->{last_datestamp} ) {
      $self->append_formatted( $tab->get_theme_var( "datemessage" ) . "\n", { datestamp => $datestamp } );
      $self->{last_datestamp} = $datestamp;
   }

   my $format = $tab->get_theme_var( $event );
   defined $format or $format = "No format defined for event $event";

   $self->append_formatted( $timestamp . $format, $args );
}

sub shift_events
{
   my $self = shift;
   my ( $howmany ) = @_;

   defined $howmany or $howmany = 1;

   my $buffer = $self->{textbuffer};

   my $start = $buffer->get_start_iter;
   my $end   = $howmany < @{ $self->{linestarts} } ? $buffer->get_iter_at_mark( $self->{linestarts}->[$howmany] )
                                                   : $buffer->get_end_iter;

   $buffer->delete( $start, $end );
   my @deleted_marks = splice @{ $self->{linestarts} }, 0, $howmany, ();
   $buffer->delete_mark( $_ ) for @deleted_marks;
}

sub scroll
{
   my $self = shift;
   my ( $dir ) = @_;

   my $adj = $self->{scrollwindow}->get_vadjustment;

   if( $dir eq 'up' ) {
      $adj->set_value( $adj->value - $adj->page_increment );
   }
   elsif( $dir eq 'down' ) {
      my $newval = $adj->value + $adj->page_increment;
      my $max = $adj->upper - $adj->page_size;
      # Check we don't go too far
      $newval = $max if $newval > $max;
      $adj->set_value( $newval );
   }
   elsif( $dir eq 'top' ) {
      $adj->set_value( $adj->lower );
   }
   elsif( $dir eq 'bottom' ) {
      $adj->set_value( $adj->upper - $adj->page_size );
   }
}

sub at_end
{
   my $self = shift;

   my $adj = $self->{scrollwindow}->get_vadjustment;

   return $adj->get_value == $adj->upper - $adj->page_size;
}

1;
