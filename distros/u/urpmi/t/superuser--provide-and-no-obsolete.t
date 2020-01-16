#!/usr/bin/perl

# a somewhat weird in urpmi that can somehow be workarounded
#
#   package "a-1" provides "c-1"
#   package "a-2" provides "c-2"
#   package "b-3" provides "c-3"
# urpmi should still be able to upgrade "a-1" into "a-2" even in presence of "b-3"
# (which do not obsolete "a" so can't be installed)

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';

my $medium_name = 'provide-and-no-obsolete';

need_root_and_prepare();

urpmi_addmedia("$medium_name $::pwd/media/$medium_name");

test(sub { urpmi('a'); check_installed_fullnames("a-2-1"); urpme('a') });
test(sub { urpmi('b'); check_installed_fullnames("a-1-1", "b-3-1"); urpme('a b') });

#- "urpmi --auto-select --auto" should do the same as "urpmi a", #31130
test(sub { urpmi('--auto-select --auto'); check_installed_fullnames("a-2-1"); urpme('a') });

sub test {
    my ($f) = @_;
    system_("rpm --root $::pwd/root -i media/$medium_name/a-1-*.rpm");
    check_installed_fullnames("a-1-1");

    $f->();
    check_nothing_installed();
}
