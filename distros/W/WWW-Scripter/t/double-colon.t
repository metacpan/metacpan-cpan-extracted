#!perl -w

# Make sure WWW::Scripter can load when a :: sub is defined.  This used to
# fail, due to sloppy typing (:: instead of "::").

use lib 't';
use tests 1;

()=\&::; # Wham!

require WWW::Scripter;

pass("WWW::Scripter can load when &:: exists");