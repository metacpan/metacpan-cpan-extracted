# -*-perl-*-
# testscript for WWW::Dict::Leo::Org Class by Thomas v.D.

use Test::More qw(no_plan);

BEGIN { use_ok "WWW::Dict::Leo::Org" };
require_ok("WWW::Dict::Leo::Org");

# unfortunately I cannot add more tests, because
# this would require internet connectivity which
# is not the case for all cpan testers.
