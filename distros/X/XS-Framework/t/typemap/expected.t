use 5.016;
use warnings;
use lib 't';
use MyTest;

subtest "expected" => \&test, "MyTest::Expected";
subtest "excepted" => \&test, "MyTest::Excepted";

sub test {
    my $c = shift;
   
    subtest "void" => sub {
        my ($ok, $err);
        subtest "normal" => sub {
            $c->void_ok();
            $ok = $c->void_ok();
            ok $ok;
            ($ok, $err) = $c->void_ok();
            ok $ok;
            is $err, undef;
        };
        subtest "error" => sub {
            dies_ok { $c->void_err() };
            $ok = $c->void_err();
            ok !$ok;
            ($ok, $err) = $c->void_err();
            ok !$ok;
            is $err, XS::STL::errc::timed_out;
        };
    };
    
    subtest "non-void" => sub {
        my ($val, $err);
        subtest "normal" => sub {
            $c->ret_ok();
            $val = $c->ret_ok();
            is $val, "hi";
            ($val, $err) = $c->ret_ok();
            is $val, "hi";
            ok !$err;
        };
        subtest "error" => sub {
            dies_ok { $c->ret_err() };
            dies_ok { $val = $c->ret_err() };
            ($val, $err) = $c->ret_err();
            is $val, undef;
            is $err, XS::STL::errc::timed_out;
        };
    };
}


done_testing;
