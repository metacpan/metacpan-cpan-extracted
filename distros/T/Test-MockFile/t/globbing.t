use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test::MockFile;

my $file1 = Test::MockFile->file('/file1.txt');
my $file2 = Test::MockFile->file('/file2.txt');
my $file3 = Test::MockFile->file('/file3.jpg');
my $file4 = Test::MockFile->file('/dir1/file4.txt');
my $file5 = Test::MockFile->file('/dir2/file5.jpg');
my $file6 = Test::MockFile->file('/dir3/dir4/file6.jpg');
my $dir5  = Test::MockFile->dir('/dir3/dir5');

my @tests = (
    [ [qw< /file1.txt /file2.txt >],            '/*.txt' ],
    [ [qw< /file1.txt /file2.txt /file3.jpg >], '/*.{txt,jp{g}}' ],
    [ [qw< /file1.txt /file2.txt /file3.jpg >], '/*.txt /*.jpg' ],

    [
        [ '/dir1/file4.txt', '/dir2/file5.jpg', '/dir3/dir4' ],
        '/*/*'
    ],

    [
        [ '/dir1/file4.txt', '/dir2/file5.jpg', '/dir3/dir4', '/dir3/dir5' ],
        '/*/*'
    ],
);

is(
    [ glob('/*.txt') ],
    [],
    'glob(' . $tests[0][1] . ')',
);

is(
    [</*.txt>],
    [],
    '<' . $tests[0][1] . '>',
);

$file1->contents('1');
$file2->contents('2');
$file3->contents('3');
$file4->contents('4');
$file5->contents('5');
$file6->contents('6');

is(
    [ glob('/*.txt') ],
    $tests[0][0],
    'glob(' . $tests[0][1] . ')',
);

is(
    [</*.txt>],
    $tests[0][0],
    '<' . $tests[0][1] . '>',
);

is(
    [ glob('/*.{txt,jp{g}}') ],
    $tests[1][0],
    'glob(' . $tests[1][1] . ')',
);

is(
    [</*.{txt,jp{g}}>],
    $tests[1][0],
    '<' . $tests[1][1] . '>',
);

is(
    [</*.txt /*.jpg>],    # / (fix syntax highlighting on vim)
    $tests[2][0],
    '<' . $tests[2][1] . '>',
);

is(
    [ glob('/*.txt /*.jpg') ],
    $tests[2][0],
    'glob(' . $tests[2][1] . ')',
);

is(
    [</*/*>],             # / (fix syntax highlighting on vim)
    $tests[3][0],
    '<' . $tests[3][1] . '>',
);

my $top_dir3 = Test::MockFile->dir('/dir3');
ok( -d '/dir3', 'Directory now exists' );

ok( !-d '/dir3/dir5',    'Directory does not exist' );
ok( mkdir('/dir3/dir5'), 'Created directory successfully' );
ok( -d '/dir3/dir5',     'Directory now exists' );

is(
    [</*/*>],    # / (fix syntax highlighting on vim)
    $tests[4][0],
    '<' . $tests[4][1] . '>',
);

done_testing();
exit;
