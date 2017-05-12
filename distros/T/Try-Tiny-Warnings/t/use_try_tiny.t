use strict;
use warnings;

use Test::More tests => 4;

use Try::Tiny;
use Try::Tiny::Warnings;

use Test::Warnings;
use Test::Deep;

try_fatal_warnings {
    warn "oops";
}
catch {
    pass "made fatal";
};

try_warnings {
    warn "oops";
    warn "sorry";
}
catch {
    fail "shouldn't get here";
}
catch_warnings {
    cmp_deeply \@_ => [ re('oops'), re('sorry') ], "catch'em all";
};

cmp_deeply( 
    ( try_fatal_warnings { warn "yay" } catch { $_ } ) 
        => re('yay'), "returns the right stuff" 
);
