#!/usr/bin/env perl

use Test::More tests => 75;
use Modern::Perl;
use lib::gitroot ();

$SIG{__WARN__} = sub { die @_ };

sub test_case
{
    my ($absdir, $is_dir, $gitdirs, $expecteddir) = @_;

    my %gitdir;
    for (@$gitdirs) {
        like $_, qr!^/.*\.git!;
        $gitdir{$_}=1;
    }
    no warnings 'redefine';
    local *lib::gitroot::_is_dir = sub {
        my ($dir) = @_;
        like $dir, qr!^/.*\.git!;
        $gitdir{$dir};
    };
    is lib::gitroot::_find_git_dir_for_path_and_isdir($absdir, $is_dir), $expecteddir;
}

test_case('/A/B/C', 1, ['/A/B/.git/', '/A/B/C/.git'], '/A/B/C');
test_case('/A/B/C', 1, ['/A/.git', '/A/B/.git'], '/A/B');
test_case('/A/B/C', 1, ['/.git', '/A/.git'], '/A');
test_case('/A/B/C', 1, ['/.git'], '/');
test_case('/A/B/C', 1, ['/A/B/C/D.git'], undef);

test_case('/A/B', 1, ['/A/.git/', '/A/B/.git'], '/A/B');

test_case('/A', 1, ['/.git/', '/A/.git'], '/A');
test_case('/A', 1, ['/.git'], '/');
test_case('/A', 1, [], undef);

test_case('/', 1, ['/.git'], '/');
test_case('/', 1, ['/X.git'], undef);

test_case('/A/B/C/somefile', 0, ['/A/B/C/somefile.git', '/A/B/C/somefile/.git', '/A/B/C/.git'], '/A/B/C');
test_case('/A/B/C/somefile', 0, ['/A/B/.git'], '/A/B');
test_case('/A/B/C/somefile', 0, ['/A/.git'], '/A');
test_case('/A/B/C/somefile', 0, ['/.git'], '/');
test_case('/A/B/C/somefile', 0, ['/A/B/C/D.git'], undef);
