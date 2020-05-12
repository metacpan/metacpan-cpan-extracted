use 5.008001;

package Skipper;
use Test2::Roo::Role;

plan skip_all => "We just want to skip";

test try_me => sub { ok(0) };

1;
