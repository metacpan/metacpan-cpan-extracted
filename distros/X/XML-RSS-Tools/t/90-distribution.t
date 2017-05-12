#   $Id: 90-distribution.t 64 2008-06-28 12:31:46Z adam $

use Test::More;
use strict;

BEGIN {
    eval ' use Test::Distribution
    podcoveropts => {trustme => [qr/^(xsl|rss)_/]} ';
    if ( $@ ) {
        plan skip_all => 'Test::Distribution not installed';
    }
    else {
        Test::Distribution->import;
    }
}
