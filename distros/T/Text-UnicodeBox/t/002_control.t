use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok 'Text::UnicodeBox::Control', qw(:all);
};

isa_ok BOX_START(), 'Text::UnicodeBox::Control', 'Start';
isa_ok BOX_END(), 'Text::UnicodeBox::Control', 'End';

done_testing;
