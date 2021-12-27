#! perl

# Basic markup parsing -- regular, bold, italic and overlaps.

use strict;
use Test::More tests => 10;

use Text::Layout::Testing;

my $layout = Text::Layout::Testing->new;

my $xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The quick brown fox',
   },
  ];

$layout->set_markup("The quick brown fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The quick ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 8,
     text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' fox',
   },
  ];

$layout->set_markup("The quick <span size=8>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );
$layout->set_markup("The quick <small>brown</small> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The quick ',
   },
   { font => 'Helvetica(sans,normal,normal,11)', size => 11,
     text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' fox',
   },
  ];

# font_desc overrides fam/style/weight.
$layout->set_markup("The quick <span style='italic' font_desc='sans 11'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The quick ',
   },
   { font => 'Helvetica-BoldOblique(sans,italic,bold,10)', size => 10,
     text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' fox',
   },
  ];

$layout->set_markup("The quick <span style='italic' weight='bold' face='sans'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     underline => 'single',
     text => 'quick',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     underline => 'double', underline_color => 'blue',
     text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' fox',
   },
  ];

$layout->set_markup("The <u>quick</u> <span underline_color='blue' underline='double'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     strikethrough => 1,
     text => 'quick',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' brown fox',
   },
  ];

$layout->set_markup("The <s>quick</s> brown fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     strikethrough => 1, strikethrough_color => 'yellow',
     text => 'quick',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' brown fox',
   },
  ];

$layout->set_markup("The <span strikethrough_color='yellow' strikethrough=1>quick</span> brown fox");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     strikethrough => 1, strikethrough_color => 'yellow',
     text => 'quick',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     strikethrough_color => 'yellow',
     text => ' brown ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     strikethrough => 1, strikethrough_color => 'yellow',
     text => 'fox',
   },
  ];

$layout->set_markup("The <span strikethrough_color='yellow'><s>quick</s> brown <span strikethrough=1>fox</span></span>");
is_deeply( $layout->_debug_text, $xp );

$xp =
  [
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => 'The quick ',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     overline => 'double', overline_color => 'red',
     text => 'brown',
   },
   { font => 'Times-Roman(times,normal,normal,10)', size => 10,
     text => ' fox',
   },
  ];

$layout->set_markup("The quick <span overline_color='red' overline='double'>brown</span> fox");
is_deeply( $layout->_debug_text, $xp );

