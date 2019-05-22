# -*- perl -*-

# t/020-errors.t - tests of invalid input
use Test::More;

use vars::i;     # Fatal if we can't load

# Use string eval + `use strict` to trap undefined variables
sub eval_dies_ok {
    eval $_[0];
    ok($@, $_[1] || ('Died as expected: ' . $_[0]));
}

# Bad sigils
eval_dies_ok q[ use vars::i '~BADSIGIL' => 1; ];
eval_dies_ok q[ use vars::i 'NOSIGIL' => 1; ];

# Elements of aggregates
eval_dies_ok q[ use vars::i '$array[0]' => 1; ];
eval_dies_ok q[ use vars::i '$hash{0}' => 1; ];

# Special variables
eval_dies_ok q[ use vars::i '$0' => 1; ];
eval_dies_ok q[ use vars::i '$1' => 1; ];
eval_dies_ok q[ use vars::i '$!' => 1; ];
eval_dies_ok q[ use vars::i '$^H' => 1; ];
eval_dies_ok q[ use vars::i '${^Foo}' => 1; ];

# Not a variable name
eval_dies_ok q[ use vars::i '$1337!' => 1; ];
eval_dies_ok q[ use vars::i '$some random thing' => 1; ];

done_testing();
