use strict;
use warnings;
use Test::More tests => 3;
use File::Spec;

# Verify that inc/Devel/CheckLib.pm creates temp files in the system
# tmpdir rather than the current directory.  Building on NFS-mounted
# source trees can fail when temp files are created in cwd (GH#76).

my $checklib_file = 'inc/Devel/CheckLib.pm';
open my $fh, '<', $checklib_file or die "Cannot open $checklib_file: $!";
my $source = do { local $/; <$fh> };
close $fh;

# 1) tempfile() call must include DIR => File::Spec->tmpdir()
like($source,
    qr/File::Temp::tempfile\([^)]*DIR\s*=>\s*File::Spec->tmpdir\(\)/s,
    'tempfile() uses DIR => File::Spec->tmpdir()');

# 2-3) Both mktemp() calls must use File::Spec->catfile(File::Spec->tmpdir(), ...)
my @mktemp_calls = ($source =~ /(File::Temp::mktemp\([^)]+\))/g);
cmp_ok(scalar @mktemp_calls, '>=', 2, 'found at least 2 mktemp() calls');

my $all_use_tmpdir = 1;
for my $call (@mktemp_calls) {
    $all_use_tmpdir = 0 unless $call =~ /File::Spec->tmpdir/;
}
ok($all_use_tmpdir, 'all mktemp() calls use File::Spec->tmpdir()');
