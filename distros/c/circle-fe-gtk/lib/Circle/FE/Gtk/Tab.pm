#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2013 -- leonerd@leonerd.org.uk

package Circle::FE::Gtk::Tab;

use strict;
use warnings;

use Glib qw( TRUE FALSE );

use File::ShareDir qw( dist_file );

use Module::Pluggable search_path => "Circle::FE::Gtk::Widget",
                      sub_name => "widgets",
                      require => 1;

our $current_tab;

sub gen_menu
{
   return [
      'Scroll to Top' => {
         accelpath => 'Tab/Scroll to Top',
         keyname   => 'Home', mod => ['control-mask'],
         code      => sub { $current_tab->scroll('top') },
      },
      'Scroll to Bottom' => {
         accelpath => 'Tab/Scroll to Bottom',
         keyname   => 'End', mod => ['control-mask'],
         code      => sub { $current_tab->scroll('bottom') },
      },
      'Scroll Up' => {
         accelpath => 'Tab/Scroll Up',
         keyname   => 'Page_Up', mod => [],
         code      => sub { $current_tab->scroll('up') },
      },
      'Scroll Down' => {
         accelpath => 'Tab/Scroll Down',
         keyname   => 'Page_Down', mod => [],
         code      => sub { $current_tab->scroll('down') },
      },
   ];
}

sub new
{
   my $class = shift;
   my %args = @_;

   my $object = $args{object};

   my $self = bless {
      object => $object,
      root => Gtk2::VBox->new(),
   }, $class;

   $object->call_method(
      method => "get_widget",
      args => [],
      on_result => sub {
         $self->{root}->add( $self->build_widget( $_[0] ) );
         $self->{root}->show_all;
      }
   );

   return $self;
}

sub get_widget
{
   my $self = shift;
   return $self->{root};
}

sub build_widget
{
   my $self = shift;
   my ( $obj ) = @_;

   foreach my $type ( widgets ) {
      next unless $obj->proxy_isa( "Circle.Widget." . $type->type );
      return $type->build( $obj, $self );
   }

   die "Cannot build widget for $obj as I don't recognise its type\n";
}

sub get_font
{
   my $self = shift;
   return Gtk2::Pango::FontDescription->from_string( $self->get_theme_var( "font" ) );
}

sub get_label
{
   my $self = shift;

   return $self->{label} if defined $self->{label};
   
   my $label = $self->{label} = Gtk2::Label->new("");

   my $object = $self->{object};
   $object->watch_property(
      property => "level",
      on_set => sub {
         my ( $level ) = @_;
         $label->modify_fg( $_ => $self->get_theme_colour( "level$level" ) ) for qw( normal active );
      },
      want_initial => 1,
   );

   return $label;
}

sub set_label_text
{
   my $self = shift;
   my ( $text ) = @_;

   $self->get_label->set_text( $text );
}

sub activated
{
   my $self = shift;

   my $object = $self->{object};

   if( $object->prop("level") > 0 ) {
      $object->call_method(
         method => "reset_level",
         args   => [],
         on_result => sub {}, # ignore
      );
   }
}

sub scroll
{
   my $self = shift;
   $self->{scroller}->scroll( @_ ) if $self->{scroller};
}

# Now read the theme
my %theme_vars;

{
   my $theme_filename;

   foreach ( $ENV{CIRCLE_FE_GTK_THEME},
             "$ENV{HOME}/.circle-fe-gtk.theme", 
             dist_file( "circle-fe-gtk", "circle-fe-gtk.theme" ) ) {
      defined $_ or next;
      -e $_ or next;

      $theme_filename = $_;
      last;
   }

   defined $theme_filename or die "Cannot find a circle-fe-gtk.theme";

   open( my $themefh, "<", $theme_filename ) or die "Cannot read $theme_filename - $!";

   while( <$themefh> ) {
      m/^\s*#/ and next; # skip comments
      m/^\s*$/ and next; # skip blanks

      m/^(\S*)=(.*)$/ and $theme_vars{$1} = $2, next;
      print STDERR "Unrecognised theme line: $_";
   }
}

sub get_theme_var
{
   my $class = shift;
   my ( $varname ) = @_;
   return $theme_vars{$varname} if exists $theme_vars{$varname};
   print STDERR "No such theme variable $varname\n";
   return undef;
}

sub translate_theme_colour
{
   my $class = shift;
   my ( $colourname ) = @_;

   return $colourname if $colourname =~ m/^#/; # Literal #rrggbb
   return $theme_vars{$colourname} if exists $theme_vars{$colourname}; # hope
   print STDERR "No such theme colour $colourname\n";
   return undef;
}

sub get_theme_colour
{
   my $class = shift;
   my ( $varname ) = @_;
   return Gtk2::Gdk::Color->parse( $theme_vars{$varname} ) if exists $theme_vars{$varname};
   print STDERR "No such theme variable $varname for a colour\n";
   return undef;
}

1;
