use v5.36;
use warnings;

no builtins;

use Test::More;

plan tests => 8;

ok !defined eval 'is_bool(true)'          => 'is_bool(true)';
ok $@ =~ /^\QBareword "true" not allowed/ => '...with correct error message';

ok !defined eval 'is_bool(false)'          => 'is_bool(false)';
ok $@ =~ /^\QBareword "false" not allowed/ => '...with correct error message';

ok !defined eval 'true()'                      => 'true()';
ok $@ =~ /^\QUndefined subroutine &main::true/ => '...with correct error message';

ok !defined eval '!false()'                     => '!false()';
ok $@ =~ /^\QUndefined subroutine &main::false/ => '...with correct error message';

done_testing();


