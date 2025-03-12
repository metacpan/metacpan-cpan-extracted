#!perl
use strict;
use warnings;
use ExtUtils::Manifest qw(fullcheck);
use Test::More tests => 2;

my ($missing, $extra) = do {
    local $ExtUtils::Manifest::Quiet = 1;
    fullcheck();
};

# HTML files can not be generated without mlpod2html installed. Don't treat
# that as an error.
my $fail = 0;
if (scalar @$missing) {
    foreach my $file (@$missing) {
        if ($file =~ m/\.html$/) {
            diag "Skipped missing file: $file";
        }
        else {
            diag "There is a file in MANIFEST but it doesn't exist: $file";
            $fail = 1;
        }
    }
}
if ($fail) {
    fail "No missing files that are in MANIFEST";
}
else {
    pass 'No missing files that are in MANIFEST';
}

ok !scalar @$extra, 'No extra files that aren\'t in MANIFEST'
  or do {
      diag "Not in MANIFEST: $_" foreach @$extra;
  };
