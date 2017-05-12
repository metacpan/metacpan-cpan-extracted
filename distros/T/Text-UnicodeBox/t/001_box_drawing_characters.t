use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
	use_ok 'Text::UnicodeBox::Utility', qw(find_box_unicode_name);
};

# One style
is find_box_unicode_name( down => 1 ), 'BOX DRAWINGS LIGHT DOWN';
is find_box_unicode_name( down => 1, left => 1 ), 'BOX DRAWINGS LIGHT DOWN AND LEFT';
is find_box_unicode_name( up => 'heavy', left => 'heavy' ), 'BOX DRAWINGS HEAVY UP AND LEFT';
is find_box_unicode_name( down => 1, up => 1 ), 'BOX DRAWINGS LIGHT VERTICAL';
is find_box_unicode_name( vertical => 1 ), 'BOX DRAWINGS LIGHT VERTICAL';
is find_box_unicode_name( vertical => 'heavy' ), 'BOX DRAWINGS HEAVY VERTICAL';

# Multiple styles
is find_box_unicode_name( down => 1, left => 'heavy' ), 'BOX DRAWINGS DOWN LIGHT AND LEFT HEAVY';
is find_box_unicode_name( down => 1, right => 'heavy', left => 'heavy' ), 'BOX DRAWINGS DOWN LIGHT AND HORIZONTAL HEAVY';
is find_box_unicode_name( down => 'double', left => 'double' ), 'BOX DRAWINGS DOUBLE DOWN AND LEFT';

# Non-existant connections
is find_box_unicode_name( down => 'double', left => 'heay' ), undef;

done_testing;

