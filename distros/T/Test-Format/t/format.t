use strict;
use warnings FATAL => 'all';

use utf8;
use open qw(:std :utf8);

use Test::More tests => 4;
use File::Temp qw(tempdir);

use Test::Format;

my $tmp_dir = tempdir( CLEANUP => 1 );
my $file_name = $tmp_dir . '/a.json';

Test::Format::_write_file($file_name, '{"b":2, "a":1, "АБВ":3}');

SKIP: {
    skip 'This is testing a test. It must fail.', 1;

    $ENV{SELF_UPDATE} = 0;
    test_format(
        files => [
            $file_name,
        ],
        format => 'pretty_json',
    );
};

$ENV{SELF_UPDATE} = 1;
test_format(
    files => [
        $file_name,
    ],
    format => 'pretty_json',
);

my $new_content = Test::Format::_read_file($file_name);
is($new_content, '{
    "a" : 1,
    "b" : 2,
    "АБВ" : 3
}
');

$ENV{SELF_UPDATE} = 0;
test_format(
    files => [
        $file_name,
    ],
    format => 'pretty_json',
);
