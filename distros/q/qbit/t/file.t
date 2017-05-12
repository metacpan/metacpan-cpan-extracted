use Test::More tests => 2;

use qbit;
use File::Temp qw(tempfile);

my $data = <<EOF;
    Test text
    Тестовый текст для проверки UTF
EOF

my (undef, $filename) = tempfile('qbit-file-test_XXXX', SUFFIX => '.txt', TMPDIR => 1, OPEN => 0);
my (undef, $append) = tempfile('qbit-file-test_XXXX', SUFFIX => '.txt', TMPDIR => 1, OPEN => 0);
END {
    unlink($filename) if $filename;
    unlink($append) if $append;
}

writefile($filename => $data);

is(
    readfile($filename),
    $data,
    "Write/Read file"
);

writefile($append => $data, append => TRUE);
writefile($append => $data, append => TRUE);

is(
    readfile($append),
    $data . $data,
    "Write/Read append file"
);
