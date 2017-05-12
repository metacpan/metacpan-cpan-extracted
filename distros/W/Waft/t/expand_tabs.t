
use Test;
BEGIN { plan tests => 3 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use base 'Waft';

my $value =   qq{\t\x0A}
            . qq{\t\x0D}
            . qq{\t\x0D\x0A}
            . qq{foo\tbar\x0A}
            . qq{foo\tbar\x0D}
            . qq{foo\tbar\x0D\x0A}
            . qq{foo\tbar\t\x0A}
            . qq{foo\tbar\t\x0D}
            . qq{foo\tbar\t\x0D\x0A}
            . qq{foo\tbar\t\t\x0A}
            . qq{foo\tbar\t\t\x0D}
            . qq{foo\tbar\t\t\x0D\x0A}
            . qq{\tfoo\tbar\t\t\x0A}
            . qq{\tfoo\tbar\t\t\x0D}
            . qq{\tfoo\tbar\t\t\x0D\x0A}
            . qq{foo\tbar\tbaz\x0A}
            . qq{foo\tbar\tbaz\x0D}
            . qq{foo\tbar\tbaz\x0D\x0A}
            . qq{foo\t\tbar\t\tbaz\x0A}
            . qq{foo\t\tbar\t\tbaz\x0D}
            . qq{foo\t\tbar\t\tbaz\x0D\x0A};

my $expanded =   qq{        \x0A}
               . qq{        \x0D}
               . qq{        \x0D\x0A}
               . qq{foo     bar\x0A}
               . qq{foo     bar\x0D}
               . qq{foo     bar\x0D\x0A}
               . qq{foo     bar     \x0A}
               . qq{foo     bar     \x0D}
               . qq{foo     bar     \x0D\x0A}
               . qq{foo     bar             \x0A}
               . qq{foo     bar             \x0D}
               . qq{foo     bar             \x0D\x0A}
               . qq{        foo     bar             \x0A}
               . qq{        foo     bar             \x0D}
               . qq{        foo     bar             \x0D\x0A}
               . qq{foo     bar     baz\x0A}
               . qq{foo     bar     baz\x0D}
               . qq{foo     bar     baz\x0D\x0A}
               . qq{foo             bar             baz\x0A}
               . qq{foo             bar             baz\x0D}
               . qq{foo             bar             baz\x0D\x0A};

ok( Waft->expand_tabs($value) eq $expanded );

ok( not eval { Waft::expand($value) eq $expanded } );

__PACKAGE__->set_waft_backword_compatible_version(0.99);
__PACKAGE__->new;
ok(     eval { Waft::expand($value) eq $expanded } );
