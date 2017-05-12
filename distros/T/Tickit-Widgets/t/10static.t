#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::Static;

my $win = mk_window;

my $static = Tickit::Widget::Static->new(
   text => "Your message here",
);

ok( defined $static, 'defined $static' );

is( $static->text,   "Your message here", '$static->text' );
is( $static->align,  0,                   '$static->align' );
is( $static->valign, 0,                   '$static->valign' );

is( $static->lines, 1, '$static->lines' );
is( $static->cols, 17, '$static->cols' );

$static->set_text( "Another message" );

is( $static->text, "Another message", '$static->set_text modifies text' );
is( $static->cols, 15, '$static->cols after changed text' );

$static->set_align( 0.2 );

is( $static->align, 0.2, '$static->set_align modifies alignment' );

$static->set_align( 'centre' );

is( $static->align, 0.5, '$static->set_align converts symbolic names' );

$static->set_valign( 0.3 );

is( $static->valign, 0.3, '$static->set_valign modifies vertical alignment' );

$static->set_valign( 'middle' );

is( $static->valign, 0.5, '$static->set_valign converts symbolic names' );

$static->set_align( 0.0 );
$static->set_valign( 0.0 );
$static->set_window( $win );

flush_tickit;

is_display( [ [TEXT("Another message")] ],
            'Display initially' );

$static->set_text( "Changed message" );

flush_tickit;

is_display( [ [TEXT("Changed message")] ],
            'Display after changed text' );

# Terminal is 80 columns wide. Text is 15 characters long. Therefore, right-
# aligned it would start in the 65th column

$static->set_align( 1.0 );

flush_tickit;

is_display( [ [BLANK(65), TEXT("Changed message")] ],
            'Display in correct location for align' );

# Terminal is 25 columns wide. Text is 1 line tall. Therefore, middle-
# valigned it would start on the 13th line

$static->set_valign( 0.5 );

flush_tickit;

is_display( [ BLANKLINES(12),
              [BLANK(65), TEXT("Changed message")] ],
            'Display in correct location for valign' );

$static->set_valign( 0.0 );
drain_termlog;

resize_term( 30, 100 );

flush_tickit;

is_display( [ [BLANK(85), TEXT("Changed message")] ],
            'Display after resize' );

$static->set_text( "A message\nwith\nmultiple lines" );

flush_tickit;

is_display( [ [BLANK(91), TEXT("A message")],
              [BLANK(96), TEXT("with")],
              [BLANK(86), TEXT("multiple lines")] ],
            'Display redrawn for multiple-line text' );

$static->set_text( "" );

is( $static->lines, 1, 'Static with empty text still consumes 1 line' );
is( $static->cols,  0, 'Static with empty text consumes 0 columns defined' );

flush_tickit;

my ( $clicked, $line, $col );
$static->set_on_click( sub { ( $clicked, $line, $col ) = @_; } );

pressmouse( "press", 1, 0, 12 );

flush_tickit;

identical( $clicked, $static, '$self for Static on_click event' );
is( $line, 0, '$line for Static on_click event' );
is( $col, 12, '$col for Static on_click event' );

# Style integration
{
   my $static = Tickit::Widget::Static->new(
      text => "Label",
      style => {
         fg          => "red",
         'fg:active' => "white",
      },
   );

   is_deeply( { $static->pen->getattrs }, { fg => 1 }, 'Styled Static pen initially' );

   $static->set_style_tag( active => 1 );

   is_deeply( { $static->pen->getattrs }, { fg => 7 }, 'Styled Static pen with tag' );
}

done_testing;
