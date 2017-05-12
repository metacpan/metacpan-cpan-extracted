use strict;
use warnings;

use Test::More;
use Test::Group;
use File::Find::Rule;
use File::Slurp;

my @files = File::Find::Rule->file()->in(qw(
    Build.PL lib t xt Changes MANIFEST.SKIP README xMakefile
));

plan tests => scalar @files;

foreach my $file (@files) {
    test "badtext in $file" => sub {
        open my $fh, "<", $file;
        while (<$fh>) {
            unless ($file eq "xt/nobadtext.t") {
                ok $_ !~ /FIXME/, "FIXME at line $.";
                ok $_ !~ /XXX/,   "XXX at line $.";
            }
            ok $_ !~ /^\s*\#.*;\s*$/, "commented out code at line $.";
            ok $_ !~ /^\s*warn\b/, "warn at line $.";

            if ($file eq "Changes") {
                ok $_ !~ /\?\?\?/, "??? on line $.";
            }
        }
    };
}

