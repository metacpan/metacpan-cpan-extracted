# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 9 };
use Text::NumericList;
ok(1); # If we made it this far, we're ok.

my $list = Text::NumericList->new;
my $mask = Text::NumericList->new;
$mask->set_string('1-10');
$list->set_mask($mask);
$\="\n"; $,=" ";
ok(sub {$list->set_string('3,2,1,3,5-7'); 
	return $list->get_string
    }, '1-3,5-7'
);

ok(sub {$list->set_string('2,oDD');
	return $list->get_string
    }, '1-3,5,7,9'
);

ok(sub {$list->set_string('eVen,5');
	return $list->get_string
    }, '2,4-6,8,10'
);

ok(sub {$list->set_string('5,-4-,7');
	return $list->get_string;
    }, '4,5,7'
);

ok(sub {$list->set_string('7-12');
	return $list->get_string;
    }, '7-10'
);

ok(sub {$list->set_string('1 -&% 4s7');
	return $list->get_string;
    },	'1-4,7'
);

ok(sub {$list->set_output_separator(';');
	return $list->get_string;
    }, '1-4;7'
);

ok(sub {$list->set_range_regexp('\.\.');
	$list->set_string('1..3;5');
	return $list->get_string;
    }, '1-3;5'
);

