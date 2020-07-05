use Test2::V0;
use Path::Tiny qw/path/;
use Fcntl qw/O_RDONLY/;

# This test is identical to the other sysopen test, except it does not use
# Test2::Plugin::Cover. The idea is to weed out sysopen errors not related to
# the plugin.

my $fh;

print STDERR "\nDEBUG A\n";
STDERR->flush();
sysopen($fh, 'fff.json', O_RDONLY);
close($fh);

print STDERR "\nDEBUG B\n";
STDERR->flush();
sysopen($fh, 'ggg.json', O_RDONLY, 0);
close($fh);

print STDERR "\nDEBUG C\n";
STDERR->flush();
sysopen($fh, 'hhh.json', O_RDONLY);
close($fh);

print STDERR "\nDEBUG D\n";
STDERR->flush();
sysopen($fh, 'iii.json', O_RDONLY);
close($fh);

print STDERR "\nDEBUG E\n";
STDERR->flush();

ok(1, "Lived");

done_testing;
