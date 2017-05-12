#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

plan(tests => 2);

my @data = (
    {
        test   => '01_example',
        path   => 'example',
        script => '01_example.pl',
        params => '-I../lib -T',
        result => <<'EOT',
See 0004, not 0005 digits.

See 0004 digits.

See the following lines
scalar
0010

arrayref
0020
0021
0022

and be lucky.

Hello Steffen Winkler!
EOT
    },
    {
        test   => '02_default_hash',
        path   => 'example',
        script => '02_default_hash.pl',
        params => '-I../lib -T',
        result => <<'EOT',
x
y
z
default
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
