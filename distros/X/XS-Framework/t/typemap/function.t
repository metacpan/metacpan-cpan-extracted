use 5.016;
use warnings;
use lib 't';
use MyTest;
use Test::Catch;
BEGIN { *F:: = *MyTest::Function:: }

subtest 'sub->function' => sub {
    subtest 'void()' => sub {
        F::s2f_vv(sub { ok 1 });
    };
    subtest 'void(int)' => sub {
        F::s2f_vi(sub {
            my $arg = shift;
            is $arg, 42;
        }, 42);
    };
    subtest 'void(int) custom' => sub {
        F::s2f_vi_custom(sub {
            my $arg = shift;
            is $arg, 142;
        }, 42);
    };
    subtest 'int(int,double)' => sub {
        my $res = F::s2f_iid(sub {
            my ($i, $d) = @_;
            is $i, 42;
            is $d, 3.14;
            return 10;
        }, 42, 3.14);
        is $res, 10;
    };
    subtest 'int(int,double) custom' => sub {
        my $res = F::s2f_iid_custom(sub {
            my ($i, $d) = @_;
            is $i, 142;
            is $d, 3.14;
            return 10;
        }, 42, 3.14);
        is $res, 20;
    };
    subtest 'sub->function->sub' => sub {
        my $src = sub {
            my $arg = shift;
            is $arg, 43;
        };
        my $sub = F::s2f2s_vi($src);
        is $sub, $src;
        $sub->(43);
    };
    subtest 'custom when no typemap' => sub {
        my $ret = F::s2f_notm(sub {
            my $arg = shift;
            is $arg, 102;
            return $arg + 100;
        }, 100);
        is $ret, 203;
    };
};

catch_run('function->sub');

done_testing;
