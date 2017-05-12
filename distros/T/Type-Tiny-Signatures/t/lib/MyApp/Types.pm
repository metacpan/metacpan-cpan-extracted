package MyApp::Types;

use Type::Library -base;
use Type::Utils   -all;

use Types::Standard ();
use Type::Tiny ();

declare "AllCaps", as   Types::Standard::Str, where { uc($_) eq $_ };
coerce  "AllCaps", from Types::Standard::Str, via   { uc($_) };

1;
