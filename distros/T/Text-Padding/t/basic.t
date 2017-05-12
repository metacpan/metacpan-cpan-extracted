use 5.012;
use strict;
use warnings;

use Test::More tests => 10;

use Text::Padding;
my $pad = Text::Padding->new( ellipsis => '-' );
my $str = '12345678';

# - center
is( $pad->center($str, 10),  " 12345678 ", "center even" );
is( $pad->center($str, 11), " 12345678  ", "center odd" );
is( $pad->center($str, 8),     "12345678", "center with no space" );
is( $pad->center($str, 5),        "1234-", "center with truncating" );

# - left
is( $pad->left($str, 10), "12345678  ", "left align" );
is( $pad->left($str, 8),    "12345678", "left no space" );
is( $pad->left($str, 5),       "1234-", "left with truncating" );

# - right
is( $pad->right($str, 10),  "  12345678", "right align" );
is( $pad->right($str, 8),     "12345678", "right with no space" );
is( $pad->right($str, 5),        "1234-", "right with truncating" );

