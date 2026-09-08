use strict;
use warnings;

# GH#38: App::cpm 0.998000 .. 0.999xxx is broken. lazy must declare a floor
# high enough to exclude that range so a consumer with a broken cpm
# preinstalled is forced to upgrade at install time. That floor lives in the
# `use App::cpm <version>` line of lib/lazy.pm -- AutoPrereqs derives the
# generated cpanfile/Makefile.PL/META.json prereq from it at release time.
# Every supported Perl is now >= 5.24, so a single static floor is enough; no
# per-Perl DynamicPrereqs conditional is needed.

use Path::Tiny qw( path );
use Test::More import => [qw( cmp_ok done_testing ok )];
use version ();

my ($floor)
    = path('lib/lazy.pm')->slurp_utf8 =~ /^use App::cpm\s+(v?[0-9._]+)/m;
ok(
    defined $floor,
    "lib/lazy.pm declares an App::cpm floor (got: @{[ $floor // 'undef' ]})"
);

cmp_ok(
    version->parse($floor), '>=', version->parse(1),
    "App::cpm floor ($floor) is >= 1, excluding the broken 0.998xxx range"
);

done_testing();
