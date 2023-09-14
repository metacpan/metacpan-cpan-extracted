#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2010-2023 -- leonerd@leonerd.org.uk

package Circle::FE::Term::Widget::Scroller 0.232470;

use v5.26;
use warnings;

use constant type => "Scroller";

use Syntax::Keyword::Match;

use Circle::FE::Term;

use Convert::Color 0.06;
use Convert::Color::XTerm;
use POSIX qw( strftime );
use String::Tagged;
use Text::Balanced qw( extract_bracketed );
use Tangence::ObjectProxy '0.16'; # watch with iterators

# Guess that we can do 256 colours on xterm or any -256color terminal
my $AS_TERM = ( $ENV{TERM} eq "xterm" or $ENV{TERM} =~ m/-256color$/ ) ? "as_xterm" : "as_vga";

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $widget = Circle::FE::Term::Widget::Scroller::Widget->new(
      classes => $obj->prop( "classes" ),
      gravity => "bottom",
   );

   my $self = bless {
      tab    => $tab,
      widget => $widget,
      last_datestamp => "",
      last_datestamp_top => "",
   };

   $widget->set_on_scrolled( sub { $self->maybe_request_more if $_[1] < 0 } );

   $tab->adopt_future(
      $obj->watch_property_with_iter(
         "displayevents", "last",
         on_set => sub {
            die "This should not happen\n";
         },
         on_push => sub {
            $self->insert_event( bottom => $_ ) for @_;
         },
         on_shift => sub {
            my ( $count ) = @_;
            $count -= $self->{iter_idx};
            $widget->shift( $count ) if $count > 0;
         },
      )->then( sub {
         ( $self->{iter}, undef, my $max ) = @_;
         $self->{iter_idx} = $max + 1;

         $self->maybe_request_more;
      })
   );

   return $widget;
}

sub maybe_request_more
{
   my $self = shift;

   my $widget = $self->{widget};
   my $idx    = $self->{iter_idx};

   my $height = $widget->window->lines;

   return if $self->{iter_fetching};

   # Stop if we've got at least 2 screenfuls more, or we're out of things to iterate
   if( $widget->lines_above > $height * 2 or !$idx ) {
      $widget->set_loading( 0 );
      return;
   }

   my $more = $height * 3;
   $more = $idx if $more > $idx;

   $self->{iter_fetching} = 1;
   $widget->set_loading( 1 );

   my $f = $self->{iter}->next_backward( $more )
      ->on_done( sub {
         ( $self->{iter_idx}, my @more ) = @_;

         $self->{iter_fetching} = 0;

         $self->insert_event( top => $_ ) for reverse @more;
         $self->maybe_request_more;
      });

   $self->{tab}->adopt_future( $f );
}

sub insert_event
{
   my $self = shift;
   my ( $end, $ev ) = @_;

   my ( $event, $time, $args ) = @$ev;

   my $tab = $self->{tab};

   my @time = localtime( $time );

   my $datestamp = strftime( Circle::FE::Term->get_theme_var( "datestamp" ), @time );
   my $timestamp = strftime( Circle::FE::Term->get_theme_var( "timestamp" ), @time );

   my $format = Circle::FE::Term->get_theme_var( $event );
   defined $format or $format = "No format defined for event $event";

   my @items = ( $self->format_event( $timestamp . $format, $args ) );

   my $widget = $self->{widget};
   match( $end : eq ) {
      case( "bottom" ) {
         unshift @items, $self->format_event( Circle::FE::Term->get_theme_var( "datemessage" ), { datestamp => $datestamp } )
            if $datestamp ne $self->{last_datestamp};

         $widget->push( @items );
         $self->{last_datestamp} = $datestamp;
      }
      case( "top" ) {
         push @items, $self->format_event( Circle::FE::Term->get_theme_var( "datemessage" ), { datestamp => $self->{last_datestamp_top} } )
            if $datestamp ne $self->{last_datestamp_top} and length $self->{last_datestamp_top};

         $widget->unshift( @items );
         $self->{last_datestamp_top} = $datestamp;
         $self->{last_datestamp} = $datestamp if !length $self->{last_datestamp};
      }
   }
}

sub format_event
{
   my $self = shift;
   my ( $format, $args ) = @_;

   my $str = String::Tagged->new();
   $self->_apply_formatting( $format, $args, $str );

   my $indent = 4;
   if( grep { $_ eq "indent" } $str->tagnames and 
       my $extent = $str->get_tag_missing_extent( 0, "indent" ) ) {
      # TODO: Should use textwidth not just char. count
      $indent = $extent->end;
   }

   return Tickit::Widget::Scroller::Item::RichText->new( $str, indent => $indent );
}

my %colourcache;
sub _convert_colour
{
   my $self = shift;
   my ( $colspec ) = @_;

   return undef if !defined $colspec;

   return $colourcache{$colspec} ||= sub {
      return Convert::Color->new( "rgb8:$1$1$2$2$3$3" )->$AS_TERM->index if $colspec =~ m/^#([0-9A-F])([0-9A-F])([0-9A-F])$/i;
      return Convert::Color->new( "rgb8:$1$2$3" )->$AS_TERM->index if $colspec =~ m/^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i;
      return Convert::Color->new( "vga:$colspec" )->index if $colspec =~ m/^[a-z]+$/;

      print STDERR "TODO: Unknown colour spec $colspec\n";
      6; # TODO
   }->();
}

sub _apply_formatting
{
   my $self = shift;
   my ( $format, $args, $str ) = @_;

   while( length $format ) {
      if( $format =~ s/^\$(\w+)// ) {
         my $val = exists $args->{$1} ? $args->{$1} : "<No such variable $1>";
         defined $val or $val = "<Variable $1 is not defined>";

         my @parts = ref $val eq "ARRAY" ? @$val : ( $val );

         my $is_initial = 1;
         my $needs_linefeed;

         foreach my $part ( @parts ) {
            my ( $text, %format ) = ref $part eq "ARRAY" ? @$part : ( $part );

            $str->append( "\n" ) if $needs_linefeed; $needs_linefeed = 0;

            # Convert some tags
            if( delete $format{m} ) {
               # Monospace
               $format{af} = 1;
               $format{bg} = "#303030";
            }
            if( delete $format{bq} ) {
               # Quoted text
               $format{bg} = "#303030";
               $format{fg} = "#00C0C0";

               # blockquotes get to be on their own line, with "> " prefixed on each
               $text = join( "\n", map { "> $_" } split m/\n/, $text );

               # surround the text by linefeeds
               $str->append( "\n" ) if !$is_initial;
               $needs_linefeed++;
            }

            # Tickit::Widget::Scroller::Item::Text doesn't like C0, C1 or DEL
            # control characters. Replace them with U+FFFD
            # Be sure to leave linefeed alone
            $text =~ s/[\x00-\x09\x0b-\x1f\x80-\x9f\x7f]/\x{fffd}/g;

            foreach (qw( fg bg )) {
               defined $format{$_} or next;
               $format{$_} = $self->_convert_colour( Circle::FE::Term->translate_theme_colour( $format{$_} ) );
            }

            $str->append_tagged( $text, %format );

            $is_initial = 0;
         }
      }
      elsif( $format =~ m/^\{/ ) {
         my $piece = extract_bracketed( $format, "{}" );
         s/^{//, s/}$// for $piece;

         if( $piece =~ m/^\?\$/ ) {
            # A conditional expansion in three parts
            #   {?$varname|IFTRUE|IFFALSE}
            my ( $varname, $iftrue, $iffalse ) = split( m/\|/, $piece, 3 );
            $varname =~ s/^\?\$//;

            if( defined $args->{$varname} ) {
               $self->_apply_formatting( $iftrue, $args, $str );
            }
            else {
               $self->_apply_formatting( $iffalse, $args, $str );
            }
         }
         elsif( $piece =~ m/ / ) {
            my ( $code, $content ) = split( m/ /, $piece, 2 );

            my ( $type, $arg ) = split( m/:/, $code, 2 );

            my $start = length $str->str;

            $self->_apply_formatting( $content, $args, $str );

            my $end = length $str->str;

            $arg = $self->_convert_colour( $arg ) if $type eq "fg" or $type eq "bg";
            $str->apply_tag( $start, $end - $start, $type => $arg );
         }
         else {
            $self->_apply_formatting( $piece, $args, $str );
         }
      }
      else {
         $format =~ s/^([^\$\{]+)//;
         my $val = $1;
         $str->append( $val );
      }
   }
}

package Circle::FE::Term::Widget::Scroller::Widget;

use base qw( Tickit::Widget::Scroller );
Tickit::Widget::Scroller->VERSION( 0.15 ); # on_scrolled
use Tickit::Widget::Scroller::Item::RichText;

sub new
{
   my $class = shift;
   return $class->SUPER::new( @_,
      gen_bottom_indicator => "gen_bottom_indicator",
      gen_top_indicator    => "gen_top_indicator",
   );
}

sub clear_lines
{
   my $self = shift;

   undef @{ $self->{lines} };

   my $window = $self->window or return;
   $window->clear;
   $window->restore;
}

sub push
{
   my $self = shift;
   my $below_before = $self->lines_below;
   $self->SUPER::push( @_ );
   if( $below_before ) {
      $self->{more_count} += $self->lines_below - $below_before;
      $self->update_indicators;
   }
}

sub set_loading
{
   my $self = shift;
   my ( $loading ) = @_;

   return if $loading == ( $self->{loading} // 0 );

   $self->{loading} = $loading;
   $self->update_indicators;
}

sub gen_bottom_indicator
{
   my $self = shift;
   my $below = $self->lines_below;
   if( !$below ) {
      undef $self->{more_count};
      return;
   }

   if( $self->{more_count} ) {
      return sprintf "-- +%d [%d more] --", $below - $self->{more_count}, $self->{more_count};
   }
   else {
      return sprintf "-- +%d --", $below;
   }
}

sub gen_top_indicator
{
   my $self = shift;
   return $self->{loading} ? "  Loading...  " : undef;
}

0x55AA;
