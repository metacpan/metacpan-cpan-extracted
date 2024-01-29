#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Tickit::Test;

use Tickit::Widget;

use Object::Pad 0.807;

my $win = mk_window;

my $RENDERED;
my $RESHAPED;
my %style_changed_values;

class StyledWidget {
   inherit Tickit::Widget;
   use Tickit::Style;

   # Needs declarative code
   BEGIN {
      style_definition base =>
         fg => 2,
         text => "Hello, world!",
         spacing => 1,
         marker => "[]",
         '<Enter>' => "activate";

      style_definition ':active' =>
         u => 1;

      style_reshape_keys qw( spacing );
      style_reshape_textwidth_keys qw( text );
      style_redraw_keys qw( marker );
   }

   use constant WIDGET_PEN_FROM_STYLE => 1;

   method cols  { 1 }
   method lines { 1 }

   method render_to_rb { $RENDERED++ }

   method reshape { $RESHAPED++ }

   method on_style_changed_values
   {
      %style_changed_values = @_;
   }
}

class StyledWidget::Subclass {
   inherit StyledWidget;
}

class StyledWidget::StyledSubclass {
   inherit StyledWidget;
   use Tickit::Style -blank;

   BEGIN {
      style_definition base =>
         fg => 7;
   }
}

class StyledWidget::CopiedSubclass {
   inherit StyledWidget;
   use Tickit::Style -copy;

   BEGIN {
      # Change just one thing
      style_definition base =>
         text => "Altered world";
   }
}

# Code-declared default style
{
   my $widget = StyledWidget->new;

   is( { $widget->get_style_pen->getattrs }, { fg => 2 }, 'style pen for default' );
   is( $widget->get_style_text, "Hello, world!", 'render text for default' );

   is( $widget->get_style_values( "<Enter>" ), "activate", 'Style for keypress' );
}

Tickit::Style->load_style( <<'EOF' );
# A comment here
#
StyledWidget {
   fg: 4;
   something-b: true; something-u: true; something-i: true;
   <Space>: activate;
}

StyledWidget.BOLD {
   b: true;
}
EOF

Tickit::Style->load_style_from_DATA;

# Stylesheet-applied default style
{
   my $widget = StyledWidget->new;

   is( { $widget->get_style_pen->getattrs },
       { fg => 4 },
       'style pen after loading style string' );

   is( { $widget->get_style_pen("something")->getattrs },
       { b => 1, u => 1, i => 1 },
       'pen can have boolean attributes' );

   is( $widget->get_style_values( "<Space>" ), "activate", 'Style for keypress from stylesheet' );
}

# Stylesheet-applied style on a class
{
   my $widget = StyledWidget->new( class => "BOLD" );

   is( { $widget->get_style_pen->getattrs },
       { fg => 4, b => 1 },
       'style pen for widget with class' );
}

{
   my $widget = StyledWidget->new( class => "PLAIN" );

   is( { $widget->get_style_pen->getattrs },
       {},
       'style pen can cancel fg' );
}

# Stylesheet-applied style with tags
{
   my $widget = StyledWidget->new;

   $widget->set_style_tag( active => 1 );

   is( { $widget->get_style_pen->getattrs },
       { fg => 4, u => 1, bg => 2 },
       'style pen for widget with style flag set' );

   is( \%style_changed_values,
       { bg => [ undef, 2 ], u => [ undef, 1 ] },
       'on_style_changed_values given style changes' );

   $widget->set_style_tag( active => 0 );

   is( { $widget->get_style_pen->getattrs },
       { fg => 4 },
       'style pen for widget with style flag cleared' );

   is( \%style_changed_values,
       { bg => [ 2, undef ], u => [ 1, undef ] },
       'on_style_changed_values given style changes after style flag clear' );
}

# Direct-applied style
{
   my $widget = StyledWidget->new(
      style => {
         fg          => 5,
         'fg:active' => 6,
      }
   );

   is( { $widget->get_style_pen->getattrs },
       { fg => 5, },
       'style pen for widget with direct style' );

   $widget->set_style_tag( active => 1 );

   is( { $widget->get_style_pen->getattrs },
       { fg => 6, u => 1, bg => 2 },
       'style pen for widget with direct style tagged' );

   is( \%style_changed_values,
       { fg => [ 5, 6 ], u => [ undef, 1 ], bg => [ undef, 2 ] },
       'on_style_changed_values for widget with direct style' );

   $widget->set_style( fg => 9, 'fg:active' => 10 );

   is( { $widget->get_style_pen->getattrs },
       { fg => 10, u => 1, bg => 2 },
       'style pen for widget after direct style changed' );

   is( \%style_changed_values,
       { fg => [ 6, 10 ] },
       'on_style_changed_values after direct style changed' );

   $widget->set_style( 'fg:active' => undef );

   is( { $widget->get_style_pen->getattrs },
       { fg => 9, u => 1, bg => 2 },
       'style pen for widget after direct style tagged key deleted' );

   is( \%style_changed_values,
       { fg => [ 10, 9 ] },
       'on_style_changed_values after direct style tagged key deleted' );

   $widget->set_style( fg => 0 );

   is( { $widget->get_style_pen->getattrs },
       { fg => 0, u => 1, bg => 2 },
       'style pen for widget after direct style sets zero' );
}

# WIDGET_PEN_FROM_STYLE
{
   my $pen_widget = StyledWidget->new(
      style => { af => 3 },
   );

   is( $pen_widget->pen->getattr( "af" ), 3, 'widget pen attr' );
   is( $pen_widget->get_style_pen->getattr( "af" ), 3, 'style pen attr' );

   $pen_widget->set_style( bg => 2 );

   is( $pen_widget->pen->getattr( "bg" ), 2, 'widget pen attr after ->set_style' );
   is( $pen_widget->get_style_pen->getattr( "bg" ), 2, 'style pen attr after ->set_style' );

   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= $_[0] };

   $pen_widget = StyledWidget->new(
      af => 4,
   );

   is( $pen_widget->pen->getattr( "af" ), 4, 'widget pen attr from args' );
   is( $pen_widget->get_style_pen->getattr( "af" ), 4, 'style pen attr from args' );

   like( $warnings, qr/^Applying legacy direct pen attribute 'af' for StyledWidget at /,
      'Legacy direct pen attribute produces a warning' );
}

# style_reshape_keys
{
   my $widget = StyledWidget->new;
   # Needs a window for ->render
   $widget->set_window( $win );

   $RESHAPED = 0;

   $widget->set_style( spacing => 2 );

   is( \%style_changed_values,
       { spacing => [ 1, 2 ] },
       'on_style_changed_values after reshape key change' );

   is( $RESHAPED, 1, '$RESHAPED 1 after ->set_style( text )' );

   $widget->set_style( text => "Goodbye" );

   is( \%style_changed_values,
       { text => [ "Hello, world!", "Goodbye" ] },
       'on_style_changed_values after reshape key change' );

   is( $RESHAPED, 2, '$RESHAPED 2 after ->set_style( text )' );

   $RESHAPED = 0;
   $RENDERED = 0;
   $widget->set_style( marker => "<>" );

   is( \%style_changed_values,
       { marker => [ "[]", "<>" ] },
       'on_style_changed_values after redraw key change' );

   flush_tickit;

   is( $RESHAPED, 0, '$RESHAPED still 0 after ->set_style( marker )' );
   is( $RENDERED, 1, '$RENDERED 1 after ->set_style( marker )' );

   $widget->set_window( undef );
}

# subclassing
{
   my $widget = StyledWidget::Subclass->new;

   is( { $widget->get_style_pen->getattrs },
       { fg => 4, },
       'style pen for widget subclass' );

   $widget = StyledWidget::StyledSubclass->new;

   is( { $widget->get_style_pen->getattrs },
       { fg => 7, },
       'style pen for widget subclass with independent style' );

   $widget = StyledWidget::CopiedSubclass->new;

   is( { $widget->get_style_pen->getattrs },
       { fg => 2},
       'widget subclass as -copy clones pen' );
   is( $widget->get_style_values( "text" ),
       "Altered world",
       'widget subclass as -copy has altered text' );
}

# A * widget type sits below all
{
   Tickit::Style->load_style( <<'EOF' );
   *.red {
      bg: "red";
   }
   * {
      u: true;
   }
EOF

   my $widget = StyledWidget->new( class => "red" );

   is( { $widget->get_style_pen->getattrs }, { fg => 4, bg => 1, u => 1 },
      'style pen for default with wildcard' );
}

done_testing;

__DATA__
StyledWidget.PLAIN {
   !fg;
}

StyledWidget:active {
   bg: 2;
}
