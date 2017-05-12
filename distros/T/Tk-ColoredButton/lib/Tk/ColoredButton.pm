package Tk::ColoredButton;

use warnings;
use strict;
use Carp;

#====================================================================
# $Author    : Djibril Ousmanou                                    $
# $Copyright : 2011                                                $
# $Update    : 18/07/2011 02:07:06                                 $
# $AIM       : Create gradient background color on a button        $
#====================================================================

use vars qw($VERSION);
$VERSION = '1.05';

use base qw/Tk::Derived Tk::Canvas::GradientColor/;
use Tk::Balloon;
use English '-no_match_vars';

Construct Tk::Widget 'ColoredButton';

# Id   =>  widget balloon
my %all_balloon;
my $count = 1;

my ( $system_button_face, $system_button_text, $system_disabled_text, $active_background, $default_font )
  = ();
my $FLASH_INTERVALL        = 300;
my $TEXTVARIABLE_INTERVALL = 300;
my $DASH                   = q{.};
my $SPACE                  = q{ };
my $INITWAIT               = 350;
my $SPACE_PLUS             = 4;

# Default Colors for all OS
if ( $OSNAME eq 'MSWin32' ) {
  $system_button_face   = 'SystemButtonFace';
  $active_background    = $system_button_face;
  $system_button_text   = 'SystemButtonText';
  $system_disabled_text = 'SystemDisabledText';
  $default_font         = '{MS Sans Serif} 8';
}
else {
  $system_button_face   = '#D9D9D9';
  $active_background    = '#ECECEC';
  $system_button_text   = 'black';
  $system_disabled_text = '#A3A3A3';
  $default_font         = '{Helvetica} 12 {bold}';
}

my %config = (
  balloon_tooltip => undef,
  tags            => {
    all      => '_cb_tag',
    text     => '_cb_text_tag',
    image    => '_cb_image_tag',
    bitmap   => '_cb_bitmap_tag',
    font     => '_cb_font_tag',
    focusin  => '_cb_focusin_tag',
    focusout => '_cb_focusout_tag',
    font     => '_cb_font_tag'
  },
  button => { press => 0, },
  ids    => { flash => undef, id_repeatdelay => undef },
  specialbutton => {
    -background         => $system_button_face,
    -borderwidth        => 2,
    -height             => 20,
    -highlightthickness => 0,
    -relief             => 'raised',
    -state              => 'normal',
    -width              => 80,
  },
  '-activebackground'    => $active_background,
  '-activeforeground'    => $system_button_text,
  '-activegradient'      => { -start_color => '#FFFFFF', -end_color => '#B2B2B2' },
  '-anchor'              => 'center',
  '-bitmap'              => undef,
  '-gradient'            => { -start_color => '#B2B2B2', -end_color => '#FFFFFF' },
  '-command'             => undef,
  '-compound'            => 'none',
  '-disabledforeground'  => $system_disabled_text,
  '-font'                => $default_font,
  '-foreground'          => $system_button_text,
  '-highlightbackground' => undef,
  '-image'               => undef,
  '-justify'             => 'center',
  '-overrelief'          => undef,
  '-padx'                => 1,
  '-pady'                => 1,
  '-relief'              => 'raised',
  '-textvariable'        => undef,
  '-tooltip'             => undef,
  '-wraplength'          => 0,
);

sub Populate {
  my ( $cw, $ref_parameters ) = @_;

  $cw->SUPER::Populate($ref_parameters);
  $cw->Advertise( 'GradientColor' => $cw );
  $cw->Advertise( 'canvas'        => $cw->SUPER::Canvas );
  $cw->Advertise( 'Canvas'        => $cw->SUPER::Canvas );

  $cw->{_cb_id} = $count;
  $cw->{_conf_cb}{$count} = \%config;

  # Default widget configuration
  foreach ( keys %{ $config{specialbutton} } ) {
    if ( defined $config{specialbutton}{$_} ) { $cw->configure( $_ => $config{specialbutton}{$_} ); }
  }

  # ConfigSpecs
  $cw->ConfigSpecs(
    -activebackground => [ 'PASSIVE', 'activeBackground', 'ActiveBackground', $active_background ],
    -activegradient   => [
      'PASSIVE', 'activeGradient',
      'ActiveGradient', { -start_color => '#FFFFFF', -end_color => '#B2B2B2' }
    ],
    -activeforeground   => [ 'PASSIVE', 'activeForeground',   'ActiveForeground',   $system_button_text ],
    -autofit            => [ 'PASSIVE', 'autofit',            'Autofit',            '0' ],
    -anchor             => [ 'PASSIVE', 'anchor',             'Anchor',             'center' ],
    -bitmap             => [ 'PASSIVE', 'bitmap',             'Bitmap',             undef ],
    -command            => [ 'PASSIVE', 'command',            'Command',            undef ],
    -compound           => [ 'PASSIVE', 'compound',           'Compound',           'none' ],
    -disabledforeground => [ 'PASSIVE', 'disabledForeground', 'DisabledForeground', $system_disabled_text ],
    -font               => [ 'PASSIVE', 'font',               'Font',               $default_font ],
    -foreground         => [ 'PASSIVE', 'foreground',         'Foreground',         $system_button_text ],
    -gradient =>
      [ 'PASSIVE', 'gradient', 'Gradient', { -start_color => '#B2B2B2', -end_color => '#FFFFFF' } ],
    -image          => [ 'PASSIVE', 'image',          'Image',          undef ],
    -imagedisabled  => [ 'PASSIVE', 'imageDisabled',  'ImageDisabled',  undef ],
    -justify        => [ 'PASSIVE', 'justify',        'Justify',        'center' ],
    -overrelief     => [ 'PASSIVE', 'overRelief',     'OverRelief',     undef ],
    -padx           => [ 'PASSIVE', 'padx',           'Padx',           1 ],
    -pady           => [ 'PASSIVE', 'pady',           'Pady',           1 ],
    -state          => [ 'PASSIVE', 'state',          'State',          'normal' ],
    -repeatdelay    => [ 'PASSIVE', 'repeatDelay',    'RepeatDelay',    undef ],
    -repeatinterval => [ 'PASSIVE', 'repeatInterval', 'RepeatInterval', undef ],
    -text           => [ 'PASSIVE', 'text',           'Text',           $SPACE ],
    -textvariable   => [ 'PASSIVE', 'textVariable',   'TextVariable',   undef ],
    -tooltip        => [ 'PASSIVE', 'tooltip',        'Tooltip',        undef ],
    -wraplength     => [ 'PASSIVE', 'wrapLength',     'WrapLength',     0 ],
  );

  $cw->Delegates( DEFAULT => $cw );

  foreach my $key (qw/ Down End Home Left Next Prior Right Up /) {
    $cw->Tk::bind( 'Tk::ColoredButton', "<Key-$key>",         undef );
    $cw->Tk::bind( 'Tk::ColoredButton', "<Control-Key-$key>", undef );
  }
  $cw->Tk::bind( '<ButtonPress-1>',   \&_press_button );
  $cw->Tk::bind( '<ButtonRelease-1>', \&_press_leave );
  $cw->Tk::bind( '<Enter>',           \&_enter );
  $cw->Tk::bind( '<Leave>',           \&_leave );
  $cw->Tk::bind( '<Configure>',       \&_create_bouton );
  $cw->Tk::bind( '<FocusIn>',         \&_focus_in );
  $cw->Tk::bind( '<FocusOut>',        \&_focus_out );

  foreach my $key (qw/ Return space /) {
    $cw->Tk::bind( "<Key-$key>",         sub { $cw->invoke; } );
    $cw->Tk::bind( "<Control-Key-$key>", sub { $cw->invoke; } );
  }

  $count++;
  return;
}

sub redraw_button {
  my $cw = shift;

  # Simulate press_leave and leave button
  my $button_press = $config{ $cw->{_cb_id} }{button}{press};
  if ( $button_press and $button_press == 1 ) { $cw->_leave; }
  $cw->_create_bouton;

  return;
}

sub invoke {
  my $cw = shift;

  my $state = $cw->cget( -state );
  return if ( $state eq 'disabled' );

  $cw->_command( $cw->cget( -command ) );

  return;
}

sub flash {
  my ( $cw, $interval ) = @_;

  my $state = $cw->cget( -state );
  return if ( $state eq 'disabled' );

  my $id_flash = $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{-flash};

  if ( defined $id_flash ) {
    $cw->itemconfigure( $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text}, -fill => $cw->cget( -foreground ) );

    $id_flash->cancel;
    $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{-flash} = undef;
  }
  if ( defined $interval and $interval == 0 ) { return; }

  if ( not defined $interval ) { $interval = $FLASH_INTERVALL; }

  my $i = 0;
  $id_flash = $cw->repeat(
    $interval,
    sub {
      if ( !Tk::Exists $cw ) { return; }
      if ( $i % 2 == 0 ) {
        $cw->itemconfigure( $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text},
          -fill => $cw->cget( -disabledforeground ) );
      }
      else {
        $cw->itemconfigure( $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text}, -fill => $cw->cget( -foreground ) );
      }
      $i++;
    }
  );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{-flash} = $id_flash;

  return $id_flash;
}

sub delete_tooltip {
  my $cw = shift;

  my $id = $cw->{_cb_id};
  if ( $id and exists $all_balloon{$id} and Tk::Exists $all_balloon{$id} ) {
    $cw->configure( -tooltip => '' );
    $all_balloon{$id}->configure( -state => 'none' );
    $all_balloon{$id}->detach($cw);
    $all_balloon{$id}->destroy;
    $all_balloon{$id} = undef;
  }

  return;
}

sub _sets_options {
  my ($cw) = @_;

  #===============================Configuration========================
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-background}         = $cw->cget( -background );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-borderwidth}        = $cw->cget( -borderwidth );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-height}             = $cw->cget( -height );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-relief}             = $cw->cget( -relief );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-state}              = $cw->cget( -state );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-width}              = $cw->cget( -width );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-cursor}             = $cw->cget( -cursor );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-highlightcolor}     = $cw->cget( -highlightcolor );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-highlightthickness} = $cw->cget( -highlightthickness );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-takefocus}          = $cw->cget( -takefocus );

  my $gradient       = $cw->cget( -gradient );
  my $activegradient = $cw->cget( -activegradient );

  if ( defined $gradient ) {
    my $ref = ref $gradient;
    if ( $ref ne 'HASH' ) {
      croak('You have to set a hash reference to -gradient option');
    }
  }
  if ( defined $activegradient ) {
    my $ref = ref $activegradient;
    if ( $ref ne 'HASH' ) {
      croak('You have to set a hash reference to -activegradient option');
    }
  }

  return;
}

sub _create_bouton {
  my ($cw) = @_;

  # clear button
  $cw->_clear_button;

  # configure all options
  $cw->_sets_options;

  # For background gradient color
  my $ref_gradient = $cw->cget( -gradient );
  $cw->set_gradientcolor( %{$ref_gradient} );

  # Create text
  $cw->_text();

  # Create image
  $cw->_image_bitmap();

  # Create tooltip
  $cw->_tooltip();

  # autofit
  my $autofit = $cw->cget( -autofit );
  if ( $autofit and $autofit == 1 ) {
    $cw->_autofit_resize;
  }

  return;
}

sub _clear_button {
  my $cw = shift;

  foreach ( $cw->find('all') ) {
    $cw->delete($_);
  }
  $cw->delete('all');

  return;
}

sub _enter {
  my $cw = shift;

  # mouse over the button
  $config{ $cw->{_cb_id} }{button}{enter} = 1;
  my $press_button = $config{ $cw->{_cb_id} }{button}{press};
  my $state        = $cw->cget( -state );
  my $tag_text     = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text};
  my $background   = $cw->cget( -background );
  $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-background} = $background;

  return if ( $state eq 'disabled' );

  if ( defined $press_button and $press_button == 1 ) {
    $cw->_press_button;
  }

  # -background
  $cw->configure( -background => $cw->cget( -activebackground ) );

  # -gradient
  $cw->set_gradientcolor( %{ $cw->cget( -activegradient ) } );

  # -overrelief
  if ( my $overrelief = $cw->cget( -overrelief ) ) {
    $cw->configure( -relief => $overrelief );
  }

  # -activeforeground
  if ( my $activeforeground = $cw->cget( -activeforeground ) ) {
    $cw->itemconfigure( $tag_text, -fill => $activeforeground );
  }

  return;
}

sub _focus_in {
  my ($cw) = @_;

  my $borderwidth = $cw->cget( -borderwidth );
  my $focusin_tag = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{focusin};
  my $height      = $cw->cget( -height );
  my $tag_all     = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{all};
  my $width       = $cw->cget( -width );

  my $id_image = $cw->createRectangle(
    $borderwidth + 1, $borderwidth + 1, $width - $borderwidth + 1, $height - $borderwidth + 1,
    -tags => [ $tag_all, $focusin_tag ],
    -dash => $DASH,
  );

  return;
}

sub _focus_out {
  my ($cw) = @_;

  my $focusin_tag = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{focusin};
  if ( $cw->find( 'withtag', $focusin_tag ) ) {
    $cw->delete($focusin_tag);
  }

  return;
}

sub _leave {
  my $cw = shift;

  # mouse not over the button
  $config{ $cw->{_cb_id} }{button}{enter} = 0;

  my $foreground = $cw->cget( -foreground );
  my $state      = $cw->cget( -state );
  my $tag_text   = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text};
  return if ( $state eq 'disabled' );

  # -background
  $cw->configure( -background => $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-background} );

  # -gradient
  my $gradient = $cw->cget( -gradient );
  $cw->set_gradientcolor( %{$gradient} );

  # -overrelief
  if ( my $overrelief = $cw->cget( -overrelief ) ) {
    $cw->configure( -relief => $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-relief} );
  }

  $cw->itemconfigure( $tag_text, -fill => $foreground );

  my $id_repeatdelay = $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay};
  if ( defined $id_repeatdelay ) {
    $id_repeatdelay->cancel;
    $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay} = undef;
  }

  # press_leave set by leave button (just relief)
  $cw->_press_leave('leave');

  return;
}

sub _press_button {
  my $cw = shift;

  my $state = $cw->cget( -state );
  return if ( $state eq 'disabled' );

  $cw->configure( -relief => 'sunken' );
  $config{ $cw->{_cb_id} }{button}{press} = 1;

  # -repeatdelay
  if ( my $repeatdelay = $cw->cget( -repeatdelay ) ) {
    my $id_repeatdelay = $cw->repeat(
      $repeatdelay,
      sub {
        if ( !Tk::Exists $cw ) { return; }
        $cw->invoke;
        $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay}->cancel;
        $config{ $cw->{_cb_id} }{button}{press_repeatdelay} = 1;

        # -repeatinterval
        if ( my $repeatinterval = $cw->cget( -repeatinterval ) ) {
          $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay} = $cw->repeat(
            $repeatinterval,
            sub {
              if ( !Tk::Exists $cw ) { return; }
              $cw->invoke;
            }
          );
        }
      }
    );
    $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay} = $id_repeatdelay;
  }

  return;
}

sub _press_leave {
  my ( $cw, $who ) = @_;

  my $state = $cw->cget( -state );
  if ( $state eq 'disabled' ) { return; }

  my $id_repeatdelay    = $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay};
  my $press_repeatdelay = $config{ $cw->{_cb_id} }{button}{press_repeatdelay};
  if ( defined $id_repeatdelay ) {
    $id_repeatdelay->cancel;
    $cw->{_conf_cb}{ $cw->{_cb_id} }{ids}{id_repeatdelay} = undef;
  }

  # Execute command
  if ( $config{ $cw->{_cb_id} }{button}{enter} == 1 ) {
    if ( not defined $press_repeatdelay or $press_repeatdelay != 1 ) {
      $cw->_command( $cw->cget( -command ) );
    }
  }

  # if widget is destroyed
  if ( !Tk::Exists $cw ) { return; }

  $config{ $cw->{_cb_id} }{button}{press_repeatdelay} = 0;

  if ( my $overrelief = $cw->cget( -overrelief ) ) {
    $cw->configure( -relief => $overrelief );
  }
  else {
    $cw->configure( -relief => $cw->{_conf_cb}{ $cw->{_cb_id} }{specialbutton}{-relief} );
  }
  if ( not defined $who or $who ne 'leave' ) {
    $config{ $cw->{_cb_id} }{button}{press} = 0;
  }

  return;
}

sub _command {
  my ( $cw, $ref_args ) = @_;

  my $state = $cw->cget( -state );
  if ( $state eq 'disabled' or not defined $ref_args ) { return; }

  my $type_arg = ref $ref_args;

  # no arguments
  if ( $type_arg eq 'CODE' ) {
    $ref_args->();
  }
  elsif ( $type_arg eq 'ARRAY' ) {
    my $command = $ref_args->[0];
    my @args;
    my $i = 0;
    foreach my $argument ( @{$ref_args} ) {
      if ( $i != 0 ) { push @args, $argument; }
      $i++;
    }
    $command->(@args);
  }

  return;
}

sub _delete_text {
  my $cw = shift;

  my $tag = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text};
  if ( $cw->find( 'withtag', $tag ) ) {
    $cw->delete($tag);
  }

  return;
}

sub _delete_image_bitmap {
  my $cw = shift;

  my $tag_image  = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{image};
  my $tag_bitmap = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{bitmap};

  if ( $cw->find( 'withtag', $tag_image ) ) {
    $cw->delete($tag_image);
  }
  if ( $cw->find( 'withtag', $tag_bitmap ) ) {
    $cw->delete($tag_bitmap);
  }

  return;
}

sub _image_bitmap {
  my $cw = shift;

  my $anchor             = $cw->cget( -anchor );
  my $bitmap             = $cw->cget( -bitmap );
  my $compound           = $cw->cget( -compound );
  my $disabledforeground = $cw->cget( -disabledforeground );
  my $font               = $cw->cget( -font );
  my $foreground         = $cw->cget( -foreground );
  my $image              = $cw->cget( -image );
  my $imagedisabled      = $cw->cget( -imagedisabled );
  my $justify            = $cw->cget( -justify );
  my $wraplength         = $cw->cget( -wraplength );
  my $state              = $cw->cget( -state );
  my $tag_all            = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{all};
  my $tag_image          = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{image};
  my $tag_bitmap         = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{bitmap};
  my $tag_text           = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text};
  my $text               = $cw->cget( -text );

  if ( $state eq 'disabled' and defined $imagedisabled ) {
    $image = $imagedisabled;
  }

  if ( not defined $image and not defined $bitmap ) {
    return;
  }

  $cw->_delete_text;
  $cw->_delete_image_bitmap;

  my ( $x_text, $y_text, $x_image, $y_image );
  ( $x_image, $y_image ) = $cw->_anchor_position;

  if ( $compound eq 'left'
    or $compound eq 'bottom'
    or $compound eq 'center'
    or $compound eq 'right'
    or $compound eq 'top' )
  {
    ( $x_text, $y_text, $x_image, $y_image ) = $cw->_anchor_position_compound($image);
  }

  if ( defined $image ) {
    my $id_image = $cw->createImage(
      $x_image, $y_image,
      -anchor => $anchor,
      -image  => $image,
      -state  => $state,
      -tags   => [ $tag_all, $tag_image ],
    );
  }
  else {
    my $id_image = $cw->createBitmap(
      $x_image, $y_image,
      -anchor => $anchor,
      -bitmap => $bitmap,
      -state  => $state,
      -tags   => [ $tag_all, $tag_bitmap ],
    );
  }

  if ( defined $x_text and defined $y_text ) {
    $cw->createText(
      $x_text, $y_text,
      -anchor  => $anchor,
      -fill    => $foreground,
      -font    => $font,
      -justify => $justify,
      -tags    => [ $tag_all, $tag_text ],
      -text    => $text,
      -width   => $wraplength,
    );
  }

  if ( $state eq 'disabled' ) {
    $cw->itemconfigure( $tag_text, -fill => $disabledforeground );
  }

  return 1;
}

sub _text {
  my $cw                 = shift;
  my $anchor             = $cw->cget( -anchor );
  my $disabledforeground = $cw->cget( -disabledforeground );
  my $font               = $cw->cget( -font );
  my $foreground         = $cw->cget( -foreground );
  my $justify            = $cw->cget( -justify );
  my $state              = $cw->cget( -state );
  my $tag_all            = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{all};
  my $tag_text           = $cw->{_conf_cb}{ $cw->{_cb_id} }{tags}{text};
  my $text               = $cw->cget( -text );
  my $ref_textvariable   = $cw->cget( -textvariable );
  my $wraplength         = $cw->cget( -wraplength );

  # -textvariable used
  if ( ref $ref_textvariable eq 'SCALAR' ) {
    $text = ${$ref_textvariable};
    $cw->configure( -textvariable => undef );
    $cw->configure( -text         => $text );

    # check modification of textvariable value
    my $id;
    $id = $cw->repeat( $TEXTVARIABLE_INTERVALL, [ \&_check_textvariable, $cw, $ref_textvariable, \$id ] );
  }
  $cw->_delete_text;

  my ( $x_text, $y_text ) = $cw->_anchor_position($anchor);
  $cw->createText(
    $x_text, $y_text,
    -anchor  => $anchor,
    -fill    => $foreground,
    -font    => $font,
    -justify => $justify,
    -tags    => [ $tag_all, $tag_text ],
    -text    => $text,
    -width   => $wraplength,
  );

  if ( $state eq 'disabled' ) {
    $cw->itemconfigure( $tag_text, -fill => $disabledforeground );
  }

  return;
}

sub _check_textvariable {
  my ( $cw, $ref_textvariable, $ref_id ) = @_;
  my $last_text = $cw->cget( -text );
  my $new_text  = ${$ref_textvariable};

  if ( ( defined $last_text and defined $new_text ) and ( $last_text ne $new_text ) ) {
    $cw->configure( -text => $new_text );
    $cw->redraw_button;
  }
  return;
}

sub _autofit_resize {
  my $cw = shift;

  my $image       = $cw->cget( -image );
  my $bitmap      = $cw->cget( -bitmap );
  my $compound    = $cw->cget( -compound );
  my $font        = $cw->cget( -font );
  my $text        = $cw->cget( -text );
  my $width       = $cw->width;
  my $height      = $cw->height;
  my $borderwidth = $cw->cget( -borderwidth );

  my $widthcw  = $cw->width;
  my $heightcw = $cw->height;
  my $padx     = $cw->cget( -padx ) + $SPACE_PLUS;
  my $pady     = $cw->cget( -pady ) + $SPACE_PLUS;

  # Text dimension
  my ( $text_width, $text_height, $image_width, $image_height );
  if ( defined $text ) {
    my $text_temp = $cw->createText(
      0, 0,
      -anchor => 'nw',
      -font   => $font,
      -text   => $text,
    );
    ( undef, undef, $text_width, $text_height ) = $cw->bbox($text_temp);
    $cw->delete($text_temp);
  }
  if ( defined $image ) {
    $image_width  = $image->width;
    $image_height = $image->height;
  }
  elsif ( defined $bitmap ) {
    my $bitmap_temp = $cw->createBitmap( 0, 0, '-bitmap' => $bitmap, -anchor => 'nw' );
    ( undef, undef, $image_width, $image_height ) = $cw->bbox($bitmap_temp);
    $cw->delete($bitmap_temp);
  }

  # autofit : Dimension, button
  my ( $total_width, $total_height ) = ( 0, 0 );

  # image/bitmap and compound
  if (
    ( defined $image or defined $bitmap )
    and (
      defined $compound
      and ($compound eq 'left'
        or $compound eq 'right'
        or $compound eq 'center'
        or $compound eq 'bottom'
        or $compound eq 'top' )
    )
    )
  {

    if ( $compound eq 'left' or $compound eq 'right' ) {
      $width = $image_width + $text_width + ( 2 * $padx );
      $height = _maxarray( [ $image_height, $text_height ] ) + ( 2 * $pady );
    }
    elsif ( $compound eq 'bottom' or $compound eq 'top' ) {
      $width = _maxarray( [ $image_width, $text_width ] ) + ( 2 * $padx );
      $height = $image_height + $text_height + ( 2 * $pady );
    }
    elsif ( $compound eq 'center' ) {
      $width  = _maxarray( [ $image_width,  $text_width ] ) +  ( 2 * $padx );
      $height = _maxarray( [ $image_height, $text_height ] ) + ( 2 * $pady );
    }
  }

  # image/bitmap replace text
  elsif ( defined $image or defined $bitmap ) {
    $width  = $image->width +  ( 2 * $padx );
    $height = $image->height + ( 2 * $pady );
  }

  # just text
  elsif ( defined $text ) {
    $width  = $text_width +  ( 2 * $padx );
    $height = $text_height + ( 2 * $pady );
  }

  if ( $widthcw != $width or $heightcw != $height ) {
    $cw->configure( -width => $width, -height => $height );
  }

  return;
}

sub _anchor_position {
  my $cw = shift;

  my $anchor      = $cw->cget( -anchor );
  my $width       = $cw->width;
  my $height      = $cw->height;
  my $borderwidth = $cw->cget( -borderwidth );
  my $padx        = $cw->cget( -padx );
  my $pady        = $cw->cget( -pady );

  my %xy_anchor_position = (
    n => {
      x => $width / 2,
      y => ( 2 * $pady ) + ( 2 * $borderwidth ),
    },
    nw => {
      x => ( 2 * $padx ) + ( 2 * $borderwidth ),
      y => ( 2 * $pady ) + ( 2 * $borderwidth ),
    },
    ne => {
      x => $width - ( 2 * $padx ) - ( 2 * $borderwidth ),
      y => ( 2 * $pady ) + ( 2 * $borderwidth ),
    },
    s => {
      x => $width / 2,
      y => $height - ( 2 * $pady ) - ( 2 * $borderwidth ),
    },
    sw => {
      x => ( 2 * $padx ) + ( 2 * $borderwidth ),
      y => $height - ( 2 * $pady ) - ( 2 * $borderwidth ),
    },
    se => {
      x => $width -  ( 2 * $padx ) - ( 2 * $borderwidth ),
      y => $height - ( 2 * $pady ) - ( 2 * $borderwidth ),
    },
    center => {
      x => $width / 2,
      y => $height / 2,
    },
    w => {
      x => ( 2 * $padx ) + ( 2 * $borderwidth ),
      y => $height / 2,
    },
    e => {
      x => $width - ( 2 * $padx ) - ( 2 * $borderwidth ),
      y => $height / 2,
    },
  );

  return ( $xy_anchor_position{$anchor}{x}, $xy_anchor_position{$anchor}{y} );
}

sub _anchor_position_compound {
  my ( $cw, $image ) = @_;

  my $anchor      = $cw->cget( -anchor );
  my $bitmap      = $cw->cget( -bitmap );
  my $compound    = $cw->cget( -compound );
  my $font        = $cw->cget( -font );
  my $text        = $cw->cget( -text );
  my $width       = $cw->width;
  my $height      = $cw->height;
  my $borderwidth = $cw->cget( -borderwidth );
  my $padx        = $cw->cget( -padx );
  my $pady        = $cw->cget( -pady );

  my ( $x_text, $y_text, $x_image, $y_image );
  ( $x_text, $y_text ) = $cw->_anchor_position;
  $x_image = $x_text;
  $y_image = $y_text;

  # Image dimension
  my ( $image_width, $image_height ) = ();
  if ( defined $image ) {
    $image_width  = $image->width;
    $image_height = $image->height;
  }
  elsif ( defined $bitmap ) {
    my $bitmap_temp = $cw->createBitmap( 0, 0, '-bitmap' => $bitmap, -anchor => 'nw' );
    ( undef, undef, $image_width, $image_height ) = $cw->bbox($bitmap_temp);
    $cw->delete($bitmap_temp);
  }

  # no image or bitmap defined
  else {
    return ( $x_text, $y_text, $x_image, $y_image );
  }

  # Text dimension
  my $text_temp = $cw->createText(
    0, 0,
    -anchor => 'nw',
    -font   => $font,
    -text   => $text,
  );
  my ( undef, undef, $text_width, $text_height ) = $cw->bbox($text_temp);
  $cw->delete($text_temp);

  my $diff_width  = $text_width - $image_width;
  my $diff_height = $text_height - $image_height;

  # Compound
  my %xy_anchor_position;
  foreach my $compound_pos (qw/ left right center top bottom /) {
    foreach my $anchor_pos (qw/ n ne nw s sw se center e w /) {
      $xy_anchor_position{$compound_pos}{$anchor_pos}{x_text}  = $x_text;
      $xy_anchor_position{$compound_pos}{$anchor_pos}{y_text}  = $y_text;
      $xy_anchor_position{$compound_pos}{$anchor_pos}{x_image} = $x_image;
      $xy_anchor_position{$compound_pos}{$anchor_pos}{y_image} = $y_image;
    }
  }

  # x
  foreach (qw / nw w sw /) {
    $xy_anchor_position{left}{$_}{x_text}   += $image_width;
    $xy_anchor_position{right}{$_}{x_image} += $text_width;
    if ( $diff_width > 0 ) {
      $xy_anchor_position{center}{$_}{x_image} += ( $diff_width / 2 );
      $xy_anchor_position{bottom}{$_}{x_image} += ( $text_width - $image_width ) / 2;
      $xy_anchor_position{top}{$_}{x_image}    += ($diff_width) / 2;
    }
    else {
      $xy_anchor_position{center}{$_}{x_text} -= ( $diff_width / 2 );
      $xy_anchor_position{bottom}{$_}{x_text} += -($diff_width) / 2;
      $xy_anchor_position{top}{$_}{x_text} -= ($diff_width) / 2;
    }
  }
  foreach (qw / n center s /) {
    $xy_anchor_position{left}{$_}{x_text} += ( $image_width / 2 );
    $xy_anchor_position{left}{$_}{x_image}
      = ( $xy_anchor_position{left}{$_}{x_text} - ( $text_width / 2 ) - ( $image_width / 2 ) );
    $xy_anchor_position{right}{$_}{x_text} -= ( $image_width / 2 );
    $xy_anchor_position{right}{$_}{x_image} += ( $text_width / 2 );
  }
  foreach (qw / ne e se /) {
    $xy_anchor_position{left}{$_}{x_image} -= $text_width;
    $xy_anchor_position{right}{$_}{x_text} -= $image_width;
    if ( $diff_width > 0 ) {
      $xy_anchor_position{center}{$_}{x_image} -= ( $diff_width / 2 );
      $xy_anchor_position{bottom}{$_}{x_image} -= ( $text_width - $image_width ) / 2;
      $xy_anchor_position{top}{$_}{x_image}    -= ($diff_width) / 2;
    }
    else {
      $xy_anchor_position{center}{$_}{x_text} += ( $diff_width / 2 );
      $xy_anchor_position{bottom}{$_}{x_text} -= -($diff_width) / 2;
      $xy_anchor_position{top}{$_}{x_text} += ($diff_width) / 2;
    }
  }

  # y
  foreach (qw / nw n ne /) {
    if ( $diff_height > 0 ) {
      $xy_anchor_position{left}{$_}{y_image}   += ( $diff_height / 2 );
      $xy_anchor_position{right}{$_}{y_image}  += ( $diff_height / 2 );
      $xy_anchor_position{center}{$_}{y_image} += ( $diff_height / 2 );
    }
    else {
      $xy_anchor_position{left}{$_}{y_text}   -= ( $diff_height / 2 );
      $xy_anchor_position{right}{$_}{y_text}  -= ( $diff_height / 2 );
      $xy_anchor_position{center}{$_}{y_text} -= ( $diff_height / 2 );
    }
    $xy_anchor_position{bottom}{$_}{y_image} += $text_height;
    $xy_anchor_position{top}{$_}{y_text}     += $image_height;
  }
  foreach (qw / sw s se /) {
    if ( $diff_height > 0 ) {
      $xy_anchor_position{left}{$_}{y_image}   -= ( $diff_height / 2 );
      $xy_anchor_position{right}{$_}{y_image}  -= ( $diff_height / 2 );
      $xy_anchor_position{center}{$_}{y_image} -= ( $diff_height / 2 );
    }
    else {
      $xy_anchor_position{left}{$_}{y_text}   += ( $diff_height / 2 );
      $xy_anchor_position{right}{$_}{y_text}  += ( $diff_height / 2 );
      $xy_anchor_position{center}{$_}{y_text} += ( $diff_height / 2 );
    }
    $xy_anchor_position{bottom}{$_}{y_image} = $height - ( 2 * $pady ) - ( 2 * $borderwidth );
    $xy_anchor_position{bottom}{$_}{y_text} -= $image_height;
    $xy_anchor_position{top}{$_}{y_image} = $xy_anchor_position{top}{$_}{y_text} - $text_height;
  }
  foreach (qw / w center e /) {
    $xy_anchor_position{bottom}{$_}{y_text} -= $text_height / 2;
    $xy_anchor_position{bottom}{$_}{y_image} += $image_height / 2;
    $xy_anchor_position{top}{$_}{y_text}     += $text_height / 2;
    $xy_anchor_position{top}{$_}{y_image} -= $image_height / 2;
  }

  foreach my $anchor_pos (qw/ n ne nw s sw se center e w /) {
    $xy_anchor_position{left}{$anchor_pos}{x_text}   += $SPACE_PLUS;
    $xy_anchor_position{right}{$anchor_pos}{x_image} += $SPACE_PLUS;
  }

  my @xy_text
    = ( $xy_anchor_position{$compound}{$anchor}{x_text}, $xy_anchor_position{$compound}{$anchor}{y_text} );
  my @xy_image
    = ( $xy_anchor_position{$compound}{$anchor}{x_image}, $xy_anchor_position{$compound}{$anchor}{y_image} );

  return ( @xy_text, @xy_image );
}

sub _tooltip {
  my $cw = shift;

  my $state = $cw->cget( -state );

  #if ( $state eq 'disabled' ) { return; }

  my $tooltip_balloon = $cw->cget( -tooltip );
  my $id              = $cw->{_cb_id};
  my $initwait        = $INITWAIT;
  my $tooltip;

  if ( ref $tooltip_balloon eq 'ARRAY' and $tooltip_balloon->[1] ) {
    $tooltip  = $tooltip_balloon->[0];
    $initwait = $tooltip_balloon->[1];
  }
  else {
    $tooltip = $tooltip_balloon;
  }

  if ( defined $tooltip ) {
    if ( exists $all_balloon{$id} and Tk::Exists $all_balloon{$id} ) {
      $all_balloon{$id}->configure( -state => 'none' );
      $all_balloon{$id}->detach($cw);
      $all_balloon{$id} = undef;
    }

    $all_balloon{$id} = $cw->Balloon( -background => 'white', );
    $all_balloon{$id}->attach(
      $cw,
      -balloonposition => 'mouse',
      -msg             => $tooltip,
      -initwait        => $initwait,
    );
  }

  return;
}

sub _maxarray {
  my ($ref_umber) = @_;
  my $max;

  for my $chiffre ( @{$ref_umber} ) {
    $max = _max( $max, $chiffre );
  }

  return $max;
}

sub _max {
  my ( $a, $b ) = @_;
  if ( not defined $a ) { return $b; }
  if ( not defined $b ) { return $a; }
  if ( not defined $a and not defined $b ) { return; }

  if   ( $a >= $b ) { return $a; }
  else              { return $b; }

  return;
}

1;

__END__

=head1 NAME

Tk::ColoredButton - Button widget with background gradient color. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  
  use Tk;
  use Tk::ColoredButton;
  
  my $mw = MainWindow->new( -background => 'white', -title => 'ColoredButton example' );
  $mw->minsize( 300, 300 );
  
  my $coloredbutton = $mw->ColoredButton(
    -text               => 'ColoredButton1',
    -autofit            => 1,
    -font               => '{arial} 12 bold',
    -command            => [ \&display, 'ColoredButton1' ],
  )->pack(qw/-padx 10 -pady 10 /);
  
  my $coloredbutton2 = $mw->ColoredButton(
    -text     => 'ColoredButton2',
    -font     => '{arial} 12 bold',
    -command  => [ \&display, 'ColoredButton2' ],
    -height   => 40,
    -width    => 160,
    -gradient => {
      -start_color  => '#FFFFFF',
      -end_color    => '#BFD4E8',
      -type         => 'mirror_vertical',
      -start        => 50,
      -number_color => 10
    },
    -activegradient => {
      -start_color  => '#BFD4E8',
      -end_color    => '#FFFFFF',
      -type         => 'mirror_vertical',
      -start        => 50,
      -number_color => 10
    },
    -tooltip => 'my button message',
  )->pack(qw/-padx 10 -pady 10 /);
  $coloredbutton2->flash();
  
  my $button = $mw->Button(
    -activebackground => 'yellow',
    -background       => 'green',
    -text             => 'Real Button',
    -font             => '{arial} 12 bold',
    -command          => [ \&display, 'Button' ],
  )->pack(qw/-ipadx 10 -pady 10 /);
  
  MainLoop;
  
  sub display {
    my $message = shift;
    if ($message) { print "$message\n"; }
  }


=head1 DESCRIPTION

Tk::ColoredButton is an extension of the B<Tk::Canvas::GradientColor> widget. It is an easy way to simulate  
a button widget with gradient background color.

=head1 STANDARD OPTIONS

The following L<Tk::Button> options are supported :

B<-activebackground>    B<-activeforeground>    B<-anchor>            B<-background>          
B<-bitmap>              B<-borderwidth>	        B<-command>           B<-compound>	            
B<-cursor>              B<-disabledforeground>  B<-font>              B<-foreground>           
B<-height>	            B<-highlightbackground> B<-highlightcolor>    B<-highlightthickness>   
B<-image>               B<-justify>             B<-padx>              B<-pady>                 
B<-relief>              B<-repeatdelay>         B<-repeatinterval>    B<-state>
B<-takefocus>           B<-text>                B<-textvariable>      B<-width>               
B<-wraplength>    

=head1 WIDGET-SPECIFIC OPTIONS 

There are many options which allow you to configure your button as you want.

=over 4

=item Name:	B<activeGradient>

=item Class: B<ActiveGradient>

=item Switch: B<-activegradient> => I<hash reference>

Specifies gradient background color to use when the mouse cursor is positioned over 
the button. Please read the options of the B<set_gradientcolor> method of L<Tk::Canvas::GradientColor> to 
understand the options.
  
  -activegradient => {
    -start_color  => '#BFD4E8',
    -end_color    => '#FFFFFF',
    -type         => 'mirror_vertical',
    -start        => 50,
    -number_color => 10
  },

Default : B<{ -start_color =E<gt> '#FFFFFF', -end_color =E<gt> '#B2B2B2' }>

=back

=over 4

=item Name:	B<autofit>

=item Class: B<Autofit>

=item Switch: B<-autofit> => I<1 or 0>

Enables automatic adjustment (width and height) of the button depending on the displayed content (text, image, bitmap, ...). 
  
  -autofit => 1,

Default : B<0>

=back

=over 4

=item Name:	B<gradient>

=item Class: B<Gradient>

=item Switch: B<-gradient>

Specifies gradient background color on the button. Please read the options of the 
B<set_gradientcolor> method of L<Tk::Canvas::GradientColor/set_gradientcolor> to understand the options.
  
  -gradient => {
    -start_color  => '#FFFFFF',
    -end_color    => '#BFD4E8',
    -type         => 'mirror_vertical',
    -start        => 50,
    -number_color => 10
  },

Default : B<{ -start_color =E<gt> '#B2B2B2', -end_color =E<gt> '#FFFFFF' }>

=item B<-height or -width>

Specifies a desired window height/width that the button widget should request from its geometry manager. 
The value may be specified in any of the forms described in the L<Tk::Canvas/"COORDINATES"> section below.

You can also use the B<autofit> option if you want to have an automatic adjustment for your button.

Default : B<-height =E<gt> 20,> B<-width =E<gt> 80,>

=back

=over 4

=item Name:	B<imageDisabled>

=item Class: B<ImageDisabled>

=item Switch: B<-imagedisabled> => I<$image_photo>

Specifies an image to display in the button when it is disabled. (
See L<Tk::Photo> or L<Tk::Image> for details of image creation.).

  -imagedisabled => $image_photo,         

Default : B<undef>

=back

=over 4

=item Name:	B<tooltip>

=item Class: B<Tooltip>

=item Switch: B<-tooltip> => I<$tooltip or [$tooltip, $iniwait?]>

Creates and attaches help balloons (using L<Tk::Balloon>). Then, 
when the mouse pauses over the button, a help balloon is popped up.

$iniwait Specifies the amount of time to wait without activity before popping up a 
help balloon. Specified in milliseconds. Defaults to B<350 milliseconds>. This applies 
to both the popped up balloon and the status bar message.

  -tooltip => 'my button message',         
  -tooltip => ['my button message', 200],

Default : B<undef>

=back

=head1 WIDGET-SPECIFIC METHODS

You can use B<invoke> method like in L<Tk::Button>.

=head2 delete_tooltip

=over 4

=item I<$button_bgc>->B<delete_tooltip>

Delete the help balloon created with tooltip option.

  $button_bgc->delete_tooltip;

=back

=head2 flash

=over 4

=item I<$button_bgc>->B<flash>(?$interval) I<in ms>

Flash the button. This is accomplished by change foreground color of the button several times, 
alternating between active and normal colors. At the end of the flash the button 
is left in the same normal/active state as when the command was invoked. This command 
is ignored if the button's state is B<disabled>.

$interval is the time in milliseconds between each alternative.

If $interval is not specified, the button will alternate between active and normal colors every 300 B<milliseconds>.

If $interval is zero, any current flash operation will be cancel.

If $interval is non-zero, the button will alternate every $interval milliseconds until 
it is explicitly cancelled via $interval to zero or using B<cancel> method to id returned.

  my $id = $button_bgc->flash(1000);
  $button_bgc->flash(0); # Cancel the flash

=back


=head2 redraw_button

=over 4

=item I<$button_bgc>->B<redraw_button>

Re-creates the button. Tk::ColoredButton supports the B<configure> and B<cget> methods 
described in the L<Tk::options> manpage. If you use configure method to change 
a widget specific option, the modification will not be display. You have to update your 
widget by redraw it using this method.

  $button_bgc->redraw_button;

=back

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-coloredbutton at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-ColoredButton>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

See also L<Tk::StyledButton> and L<Tk::Button>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::ColoredButton

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-ColoredButton>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-ColoredButton>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-ColoredButton>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-ColoredButton/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Djibril Ousmanou.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
