#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::TAP;


is_failing_tap 'ok 1', 'Invalid tap if we do not have a plan';
is_passing_tap <<'END', '... but it should be valid if we do have a plan';
1..1
ok 1 - some message
END

is_passing_tap <<'END', '... even if it is a trailing plan';
ok 1 - some message
1..1
END

is_failing_tap <<'END', '... but not if it is an embedded plan';
ok 1 - some message
1..2
ok 2
END

is_passing_tap <<'END', '... but it is ok if the plan is in nested TAP';
ok 1 - some message
begin 2 - fribble with nests
    TAP version 16
    1..2
    ok 1
    ok 2
    TAP done
ok 2 - refers to preceding block
1..2
END

is_failing_tap <<'END', '... or if there is more than one plan';
1..2
ok 1 - some message
ok 2
1..2
END

is_failing_tap <<'END', '... but not if the plan is wrong';
1..3
ok 1
ok 2
END

is_failing_tap <<'END', 'We should fail if we have failing tests';
1..3
ok 1
not ok 2 this is a failure
ok 3
END

is_passing_tap <<'END', '... unless it is a TODO test';
1..3
ok 1
not ok 2 this is a failure # TODO psych!
ok 3
END
