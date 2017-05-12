package Text::Autoformat::NullHang;
$Text::Autoformat::NullHang::VERSION = '1.74';
use 5.006;
use strict;
use warnings;

sub new       { bless {}, $_[0] }
sub stringify { "" }
sub length    { 0 }
sub incr      {}
sub empty     { 1 }
sub signature     { "" }
sub fields { return 0 }
sub field { return "" }
sub val { return "" }

1;
