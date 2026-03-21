use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp;

use Test::MockFile qw< nostrict >;

# Issue #158: glob should return real files when nothing is mocked
# for the given pattern.

my $dir = File::Temp->newdir();

# Create real files on disk
my $log_file = "$dir/file.log";
open( my $fh, '>', $log_file ) or die "Cannot create $log_file: $!";
print {$fh} "test";
close $fh;

my $txt_file = "$dir/file.txt";
open( $fh, '>', $txt_file ) or die "Cannot create $txt_file: $!";
print {$fh} "test";
close $fh;

# Test 1: glob should find real files when nothing is mocked
my @logs = glob("$dir/*.log");
is \@logs, [$log_file], 'glob finds real .log file on disk';

# Test 2: glob with multiple results
my @all = sort glob("$dir/*");
is \@all, [ sort( $log_file, $txt_file ) ], 'glob finds all real files on disk';

# Test 3: glob returns empty for non-matching pattern
my @none = glob("$dir/*.xyz");
is \@none, [], 'glob returns empty for non-matching pattern';

# Test 4: diamond operator (angle bracket) glob should also work
my @diamond = <$dir/*.log>;
is \@diamond, [$log_file], 'angle bracket glob finds real .log file on disk';

# Test 5: mocked files should still work alongside real files, results sorted
my $mock = Test::MockFile->file("$dir/mock.log", "mocked");
my @mixed = glob("$dir/*.log");
is \@mixed, [ sort( $log_file, "$dir/mock.log" ) ],
    'glob returns both real and mocked files in sorted order';

# Test 6: mocked file that shadows a real file (no duplicates)
my $shadow = Test::MockFile->file($log_file, "shadow");
my @shadowed = glob("$dir/*.log");
is \@shadowed, [ sort( $log_file, "$dir/mock.log" ) ],
    'glob returns mocked files that shadow real files without duplicates';

done_testing();
