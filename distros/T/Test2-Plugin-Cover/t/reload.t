use Test2::V0;
use Test2::Plugin::Cover ();

# Regression test: loading the module a second time (preload systems can clear
# %INC and re-require) used to re-install the op hooks with themselves as the
# "original" handlers, causing infinite recursion and a segfault on the very
# next sub call.

Test2::Plugin::Cover->enable;

sub foo { 42 }
is(foo(), 42, "sub calls work after first load");

delete $INC{'Test2/Plugin/Cover.pm'};
{
    local $SIG{__WARN__} = sub { };    # silence redefine warnings
    require Test2::Plugin::Cover;
}

is(foo(), 42, "sub calls still work after the module is loaded a second time");

# The second load's BEGIN block reset $ENABLED, make sure collection still
# works end to end after re-enabling.
Test2::Plugin::Cover->enable;
Test2::Plugin::Cover->reset_coverage;
foo();
ok(
    (grep { m/reload\.t/ } keys %Test2::Plugin::Cover::REPORT),
    "coverage collection still works after reload"
);

Test2::Plugin::Cover->reset_coverage;

done_testing;
