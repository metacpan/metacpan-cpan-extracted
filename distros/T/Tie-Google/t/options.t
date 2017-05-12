#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;
use Test::More;

use Tie::Google;
use File::Spec::Functions qw(catfile updir);
use Cwd qw(cwd);

my ($G, $g, $KEY, %options, $OPTIONS);
$KEY = -d "t" ? catfile(cwd, ".googlekey")
              : catfile(cwd, updir, ".googlekey");
$OPTIONS = Tie::Google::OPTIONS();
%options = (
    "ie"            => "utf-64",
    "oe"            => "utf-64",
#    "debug"         => 1,
    "starts_at"     => $$,
    "max_results"   => $$ ^ 2,
);

if (-z $KEY) {
    plan skip_all => "No key provided";
    exit;
} else {
    plan tests => 1;
}

tie $g, 'Tie::Google', $KEY, "perl", \%options;

# eq_hash isn't working for me :(
# eq_hash($G->[$OPTIONS], \%options);
is(join(":", sort keys %{ tied($g)->[$OPTIONS] }),
   join(":", sort keys %options),
   "tied(\$g)->[OPTIONS] is sane");
 
