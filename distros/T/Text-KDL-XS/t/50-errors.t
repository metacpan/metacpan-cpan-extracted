use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

eval { parse_kdl("foo {\n") };
ok $@, 'unclosed brace dies';
like $@, qr/KDL/i, 'error mentions KDL';

eval { parse_kdl("== invalid ==\n") };
ok $@, 'malformed input dies';

eval { parse_kdl(undef) };
ok $@, 'undef source dies';

done_testing;
