#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use t::Util;
use Test::More;

subtest 'ls', sub {
    my $ftp = default_mock_prepare(
        ls => sub {
            return qw(aaa bbb ccc);
        }
    );

    is_deeply([$ftp->ls], [qw(aaa bbb ccc)]);
    done_testing();
};

subtest 'dir', sub {
    my $ftp = default_mock_prepare(
        dir => sub {
            return (
                "-rw-r--r--  1 tsucchi  tsucchi  740 May 29 08:29 aaa",
                "-rwxr-xr-x  1 tsucchi  tsucchi   85 Apr 24 08:27 bbb",
                "-rwxr-xr-x  1 tsucchi  tsucchi  681 May 29 08:31 ccc",
            )
        }
    );

    my @dir_expected = (
        "-rw-r--r--  1 tsucchi  tsucchi  740 May 29 08:29 aaa",
        "-rwxr-xr-x  1 tsucchi  tsucchi   85 Apr 24 08:27 bbb",
        "-rwxr-xr-x  1 tsucchi  tsucchi  681 May 29 08:31 ccc",
    );
    is_deeply([$ftp->dir], \@dir_expected);
    done_testing();
};

subtest 'pwd', sub {
    my $ftp = default_mock_prepare(
        pwd => sub {
            return "some/dir";
        }
    );

    is($ftp->pwd, "some/dir");
    done_testing();
};

subtest 'other methods', sub {
    my @methods = all_methods_in_net_ftp();

    for my $method ( @methods ) {
        my $called_method = "";
        my $called_arg    = "";
        my $ftp = default_mock_prepare(
            $method => sub {
                my ($self, $arg) = @_;
                $called_method = $method;
                $called_arg    = $arg;
            }
        );
        {
            no strict 'refs';
            $ftp->$method("arg_for_$method");
        }
        is($called_method, $method, $method);
        is($called_arg,    "arg_for_$method", $method);
    }
    done_testing();
};

done_testing();

