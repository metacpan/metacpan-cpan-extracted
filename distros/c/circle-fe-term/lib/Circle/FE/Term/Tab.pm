#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2012-2015 -- leonerd@leonerd.org.uk

package Circle::FE::Term::Tab;

use strict;
use warnings;

use Tickit::Widget::Tabbed;
use base qw( Tickit::Widget::Tabbed::Tab );
Tickit::Widget::Tabbed->VERSION( '0.019' );

use Tickit::Term 0.27; # setctl_str

use Circle::FE::Term;

use Module::Pluggable search_path => "Circle::FE::Term::Widget",
                      sub_name => "widgets",
                      require => 1,
                      inner => 0;

use Tickit::Widget::Static;

sub new
{
   my $class = shift;
   my ( $tabbed, %args ) = @_;

   my $object = delete $args{object};
   my $self;

   my $watch_tag;
   if( $object->proxy_isa( "Circle.RootObj" ) ) {
      $args{label} = "Global";
   }
   else {
      $args{label} = $object->prop( "tag" );
      $watch_tag++;
   }

   $self = $class->SUPER::new( $tabbed, %args );
   $self->{object} = $object;
   $self->{term} = $tabbed->window->term;

   $self->adopt_future(
      $object->call_method(
         get_widget => (),
      )->on_done( sub {
         $self->widget->add( $self->build_widget( $_[0] ), expand => 1 );
      })
   );

   $self->adopt_future(
      $object->watch_property_with_initial(
         "level",
         on_set => sub {
            my ( $level ) = @_;
            $self->set_level( $level );
         },
      )
   );

   $self->adopt_future(
      $object->subscribe_event(
         "raise",
         on_fire => sub {
            $self->activate;
         },
      )
   );

   if( $watch_tag ) {
      $self->adopt_future(
         $object->watch_property(
            "tag",
            on_set => sub {
               my ( $newtag ) = @_;
               $self->set_label_text( $newtag );
            },
         )
      );
   }

   $self->set_on_activated( 'activated' );

   return $self;
}

sub adopt_future
{
   my $self = shift;
   my ( $f ) = @_;

   my $futures = $self->{futures} //= {};

   $futures->{"$f"} = $f;

   $f->on_ready( sub {
      delete $futures->{shift()};
   });
}

sub build_widget
{
   my $self = shift;
   my ( $obj ) = @_;

   foreach my $type ( widgets ) {
      next unless $obj->proxy_isa( "Circle.Widget." . $type->type );
      return $type->build( $obj, $self );
   }

   die "Cannot build widget for $obj as I don't recognise its type - " . join( ", ", map { $_->name } $obj->proxy_isa ) . "\n";
}

sub level
{
   my $self = shift;
   return $self->{object}->prop( "level" );
}

sub set_level
{
   my $self = shift;
   my ( $level ) = @_;

   $self->set_pen( Circle::FE::Term->get_theme_pen( "level$level" ) );
}

sub set_label_text
{
   my $self = shift;
   my ( $text ) = @_;

   $self->{label} = $text;

   return unless my $tab = $self->{tab};
   $tab->set_label( $text );
}

sub label
{
   my $self = shift;
   return $self->{label};
}

sub label_short
{
   my $self = shift;
   my $label = $self->label;
   $label =~ s/([a-z0-9])([a-z0-9]+)/$1/gi;
   return $label;
}

sub activated
{
   my $self = shift;

   my $object = $self->{object};

   if( $object->prop("level") > 0 ) {
      $self->adopt_future(
         $object->call_method(
            reset_level => (),
         )
      );
   }

   my $tag = $object->prop("tag") // "Global";
   my $title = sprintf "%s - %s", $tag, "Circle";

   $self->{term}->setctl_str( icontitle_text => $title );
}

0x55AA;
