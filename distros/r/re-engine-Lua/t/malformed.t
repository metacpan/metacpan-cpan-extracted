use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}
plan tests => 3;

use re::engine::Lua;

throws_ok { "aaa" =~ /(.)(./ } '/unfinished capture/', 'unfinished capture';

throws_ok { "aaa" =~ /a[0-/ } '/malformed pattern/', 'malformed pattern';

throws_ok { "aaa" =~ /%b[/ } '/malformed pattern/', 'malformed pattern';

