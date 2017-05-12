#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING} or plan
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

my @data = (
    {
        test   => '01_try_chain_scalar',
        path   => 'example',
        script => '01_try_chain_scalar.pl',
        params => '-I../lib -T',
        result => <<'EOT',
1foo
2baz
3item
4value
5undef
6undef
7undef
8undef
9undefundef
11try_chain finally
11error of try_chain
13try finally
13error of try
EOT
    },
    {
        test   => '02_call_m_scalar',
        path   => 'example',
        script => '02_call_m_scalar.pl',
        params => '-I../lib -T',
        result => <<'EOT',
1foo
2foo
3baz
4item
5item
6value
7value
8undef
9undef
10undef
11undef
12undef
13undef
14undef
15undef
EOT
    },
    {
        test   => '03_try_chain_list',
        path   => 'example',
        script => '03_try_chain_list.pl',
        params => '-I../lib -T',
        result => <<'EOT',
1foo
2barbaz
3item
4value
5
6
7
8
EOT
    },
    {
        test   => '04_call_m_list',
        path   => 'example',
        script => '04_call_m_list.pl',
        params => '-I../lib -T',
        result => <<'EOT',
1foo
2foo
3barbaz
4item
5item
6value
7value
8
9
10
11
12undef
13undef
14undef
15undef
EOT
    },
);

plan tests => 0 + @data;

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{params} $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
