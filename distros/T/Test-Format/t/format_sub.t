use strict;
use warnings FATAL => 'all';

use utf8;
use open qw(:std :utf8);

use Test::More tests => 4;
use File::Temp qw(tempdir);

use Test::Format;

sub align {
    my ($content) = @_;

    my $new_content = '';

    my @lines = split /\n/, $content;
    my $max_width = 1;

    foreach my $line (@lines) {
        $line =~ /^(\S+)\s+(\S+)\z/;
        my $l = length($1);
        $max_width = $l if $l > $max_width;
    }

    my $format = "%-" . ($max_width + 3) . "s %s\n";
    foreach my $line (@lines) {
        $line =~ /^(\S+)\s+(\S+)\z/;
        $new_content .= sprintf $format,
            $1,
            $2,
            ;
    }

    return $new_content;
};

my $tmp_dir = tempdir( CLEANUP => 1 );
my $file_name = $tmp_dir . '/file.asdf';

Test::Format::_write_file($file_name, '1 a
22 bb
333 ccc
4444 dddd
333 ccc
АБВ ГДЕ
');

SKIP: {
    skip 'This is testing a test. It must fail.', 1;

    $ENV{SELF_UPDATE} = 0;
    test_format(
        files => [
            $file_name,
        ],
        format_sub => \&align,
    );
};

$ENV{SELF_UPDATE} = 1;
test_format(
    files => [
        $file_name,
    ],
    format_sub => \&align,
);

my $new_content = Test::Format::_read_file($file_name);
is($new_content, '1       a
22      bb
333     ccc
4444    dddd
333     ccc
АБВ     ГДЕ
');

$ENV{SELF_UPDATE} = 0;
test_format(
    files => [
        $file_name,
    ],
    format_sub => \&align,
);
