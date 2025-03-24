#! perl

# Basic markup parsing -- registered shortcodes.

use strict;
use Test::More tests => 4;

use Text::Layout::Testing;

my $layout = Text::Layout::Testing->new;

my $xp;

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => 'The quick ',
   },
   { font => 'Times-Bold(times,normal,bold,10)', size => 10,
     type => "text", text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => ' fox',
   },
  ];

$layout->set_markup("The quick <b>brown</b> fox");
is_deeply( $layout->_debug_text, $xp );

# Global define.
Text::Layout->register_shortcode( "xx", "weight='bold'" );
$layout->set_markup("The quick <xx>brown</xx> fox");
is_deeply( $layout->_debug_text, $xp );

# Local define.
$layout->register_shortcode( "xx", "style='italic'" );
$layout->set_markup("The quick <xx>brown</xx> fox");
$xp->[1] =
   { font => 'Times-Italic(times,italic,normal,10)', size => 10,
     type => "text", text => 'brown',
   };
is_deeply( $layout->_debug_text, $xp );

# Remove local define.
$layout->register_shortcode( "xx", "style='italic'", remove => 1 );
$layout->set_markup("The quick <xx>brown</xx> fox");
$xp->[1] =
   { font => 'Times-Bold(times,normal,bold,10)', size => 10,
     type => "text", text => 'brown',
   };
is_deeply( $layout->_debug_text, $xp );
