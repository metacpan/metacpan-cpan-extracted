#! perl

# Basic markup parsing -- regular, bold, italic and overlaps.

use strict;
use Test::More tests => 9;

use Text::Layout::Testing;

my $layout = Text::Layout::Testing->new;

my $xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => 'The quick brown fox',
   },
  ];

$layout->set_markup("The quick brown fox");
is_deeply( $layout->_debug_text, $xp );

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

$layout->set_markup("The quick <span weight='bold'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );
$layout->set_markup("The quick <b>brown</b> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => 'The quick ',
   },
   { font => 'Times-Italic(times,italic,normal,10)', size => 10,
     type => "text", text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => ' fox',
   },
  ];

$layout->set_markup("The quick <span style='italic'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );
$layout->set_markup("The quick <i>brown</i> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => 'The quick ',
   },
   { font => 'Times-BoldItalic(times,italic,bold,10)', size => 10,
     type => "text", text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => ' fox',
   },
  ];

$layout->set_markup("The quick <span style='italic' weight='bold'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );
$layout->set_markup("The quick <i><b>brown</b></i> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => 'The ',
   },
   { font => 'Times-Italic(times,italic,normal,10)', size => 10,
     type => "text", text => 'quick ',
   },
   { font => 'Times-BoldItalic(times,italic,bold,10)', size => 10,
     type => "text", text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => ' fox',
   },
  ];

$layout->set_markup("The <i>quick <b>brown</b></i> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => 'The ',
   },
   { font => 'Times-BoldItalic(times,italic,bold,10)', size => 10,
     type => "text", text => 'quick',
   },
   { font => 'Times-Bold(times,normal,bold,10)', size => 10,
     type => "text", text => ' brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     type => "text", text => ' fox',
   },
  ];

$layout->set_markup("The <b><i>quick</i> brown</b> fox");
is_deeply( $layout->_debug_text, $xp );
