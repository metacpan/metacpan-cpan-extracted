use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use File::Spec;
use File::Basename qw/dirname/;
use File::Slurp;
use Time::Strptime qw/strptime/;
use POSIX qw/tzset/;

use Text::Diff::Unified::XS;

local $ENV{TZ} = 'GMT';
local $Time::Strptime::TimeZone::DEFAULT = 'GMT';
tzset();

subtest 'from string' => sub {
    my $data_dir = File::Spec->catfile(dirname(__FILE__), 'data');
    my $data_a   = read_file(File::Spec->catfile($data_dir, 'a.txt'));
    my $data_b   = read_file(File::Spec->catfile($data_dir, 'b.txt'));
	my $diff_str = read_file(File::Spec->catfile($data_dir, 'diff.txt'));

    is diff(\$data_a, \$data_b), $diff_str;
};

subtest 'from file' => sub {
    my $data_dir = File::Spec->catfile(dirname(__FILE__), 'data');
    my $file_a   = File::Spec->catfile($data_dir, 'a.txt');
    my $file_b   = File::Spec->catfile($data_dir, 'b.txt');

    my ($mtime_a) = strptime('%F %T', '2016-01-03 12:34:56');
    my ($mtime_b) = strptime('%F %T', '2016-05-12 23:45:00');
    utime $mtime_a, $mtime_a, $file_a;
    utime $mtime_b, $mtime_b, $file_b;

    my $header =
        "--- $file_a\tSun Jan  3 12:34:56 2016\n".
        "+++ $file_b\tThu May 12 23:45:00 2016\n";
	my $diff   = read_file(File::Spec->catfile($data_dir, 'diff.txt'));

    is diff($file_a, $file_b), $header . $diff;
};

done_testing;

