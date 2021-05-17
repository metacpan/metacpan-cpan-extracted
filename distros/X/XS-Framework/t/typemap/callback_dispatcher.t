use 5.016;
use warnings;
use lib 't';
use MyTest;
use Test::Exception;

my ($ret, $sub, $cnt);

my $obj = MyTest::DispatchingObject->new;

subtest "add/remove" => sub {
    ok(!$obj->vs->has_listeners, "no listeners");
    my @sub = (sub {}, sub {});
    $obj->vs->add($sub[0]);
    ok($obj->vs->has_listeners, "has listeners");
    $obj->vs->add($sub[1]);
    
    $obj->vs->remove($sub[0]);
    ok($obj->vs->has_listeners, "still has listeners");
    
    $obj->vs->remove($sub[1]);
    ok(!$obj->vs->has_listeners, "empty");
};

subtest "remove_all" => sub {
    my @sub = (sub {}, sub {});
    $obj->vs->add($sub[0]);
    $obj->vs->add($sub[1]);
    ok($obj->vs->has_listeners, "has listeners");
    $obj->vs->remove_all;
    ok(!$obj->vs->has_listeners, "all listeners removed");
};

subtest "wrong number of params -> croak" => sub {
    dies_ok { $obj->vs->call } "less params";
    dies_ok { $obj->vs->call("str", "str") } "more params";
};

subtest "void(string) dispatcher" => sub {
	subtest "no params to create()" => sub {
	    $obj->vs->add(sub { is(shift, "value") });
	    $obj->vs->call("value");
	    $obj->vs->remove_all;
	    done_testing(1);
	};
    
    subtest "nullptr to create()" => sub {
        $obj->vs("nullptr")->add(sub { is(shift, "value") });
        $obj->vs("nullptr")->add(sub { ok 1 });
        $obj->vs->call("value");
        $obj->vs->remove_all;
        done_testing(2);
    };
    
    subtest "custom pair with out function" => sub {
        $obj->vs("pair_out")->add(sub { is(shift, "value custom_out") });
        $obj->vs->call("value");
        $obj->vs->remove_all;
        done_testing(1);
    };
    
    subtest "custom pair with in function" => sub {
        $obj->vs("pair_in")->add(sub { is(shift, "value custom_in") });
        $obj->vs("pair_in")->call("value");    
        $obj->vs->remove_all;
        done_testing(1);
    };
    
    subtest "custom pair with in&out function" => sub {
        $obj->vs("pair_inout")->add(sub { is(shift, "value custom_in custom_out") });
        $obj->vs("pair_inout")->call("value");
        $obj->vs->remove_all;
        done_testing(1);
    };
    
    subtest "ext callback" => sub {
        subtest "add/remove" => sub {
            my $sub1 = sub { ok 1; my $n = shift; $n->(@_) };
            my $sub2 = sub { ok 1 };
            $obj->vs->add_event_listener($sub1);
            $obj->vs->add_event_listener($sub2);
            $obj->vs->call("");
            $obj->vs->remove_event_listener($sub1);
            ok $obj->vs->has_listeners;
            $obj->vs->call("");
            $obj->vs->remove_event_listener($sub2);
            ok !$obj->vs->has_listeners;
            $obj->vs->call("");
            done_testing(5);
        };
        subtest "not forwarding" => sub {
            $obj->vs->add_event_listener(sub {
                my ($e, $val) = @_;
                is($val, "value", "val ok");
            });
            $obj->vs->add_event_listener(sub { ok 1; ok 1; });
            $obj->vs->call("value");
            $obj->vs->remove_all;
            done_testing(1);
        };
        subtest "forwarding" => sub {
            $obj->vs->add_event_listener(sub {
                is($_[1], "value", "val1 ok");
                $_[0]->($_[1].2);
            });
            $obj->vs->add_event_listener(sub {
                is($_[1], "value2", "val2 ok");
                $_[0]->($_[1].3);
            });
            $obj->vs->add_event_listener(sub {
                is($_[1], "value23", "val3 ok");
                $_[0]->($_[1]);
            });
            $obj->vs->call("value");
            $obj->vs->remove_all;
            done_testing(3);
        };
        subtest "next wrong arguments" => sub {
            $obj->vs->add_event_listener(sub {
                my $next = shift;
                dies_ok { $next->() } "less";
                dies_ok { $next->(1, 2) } "more";
            });
            $obj->vs->call("value");
            $obj->vs->remove_all;
            done_testing(2);
        };
        subtest "no retvals" => sub {
            $obj->vs->add_event_listener(sub { ok 1; return 100 });
            my @ret = $obj->vs->call("value");
            is(scalar @ret, 0);
            $obj->vs->remove_all;
            done_testing(2);
        };
    };
};

subtest "int(void) dispatcher" => sub {
    dies_ok { $obj->iv->call(1) } "wrong args to call()";
    subtest "simple cb" => sub {
        $obj->iv->add(sub { ok 1; return 123 });
        my @ret = $obj->iv->call;
        cmp_deeply(\@ret, [undef], "simple cb cannot return values");
        $obj->iv->remove_all;
        done_testing(2);
    };
    subtest "single cb" => sub {
        $obj->iv->add_event_listener(sub {
            my @ret = $_[0]->();
            cmp_deeply(\@ret, [undef], "next() returns empty when there is no next");
            return 100;
        });
        is $obj->iv->call, 100;
        $obj->iv->remove_all;
        done_testing(2);
    };
    subtest "multi cb" => sub {
        $obj->iv->add_event_listener(sub { ok 1; return $_[0]->() + 100 });
        $obj->iv->add_event_listener(sub { ok 1; return 11 });
        is $obj->iv->call, 111;
        $obj->iv->remove_all;
        done_testing(3);
    };
    subtest "empty return (from callback)" => sub {
        $obj->iv->add_event_listener(sub { ok 1; return });
        my @ret = $obj->iv->call;
        cmp_deeply(\@ret, [undef], "nothing returned");
        $obj->iv->remove_all;
        done_testing(2);
    };
    subtest "undef from callback" => sub {
        no warnings 'uninitialized';
        $obj->iv->add_event_listener(sub { ok 1; return undef });
        my @ret = $obj->iv->call;
        cmp_deeply(\@ret, [undef], "default type value returned");
        $obj->iv->remove_all;
        done_testing(2);
    };
    subtest "empty return (no callbacks)" => sub {
        my @ret = $obj->iv->call;
        cmp_deeply(\@ret, [undef], "nothing returned");
        done_testing(1);
    };
};

subtest "int(string) dispatcher" => sub {
	subtest "wrong number of params -> croak" => sub {
	    dies_ok { $obj->is->call } "less params";
	    dies_ok { $obj->is->call("str", "str") } "more params";
	};
	subtest "default" => sub {
	    $obj->is->add_event_listener(sub {
	        is $_[1], "value";
	        return 123;
	    });
	    is $obj->is->call("value"), 123;
	    $obj->is->remove_all;
	    done_testing(2);
	};
    subtest "nullptr" => sub {
        $obj->is("nullptr")->add_event_listener(sub {
            is $_[1], "value";
            return 123;
        });
        is $obj->is("nullptr")->call("value"), 123;
        $obj->is->remove_all;
        done_testing(2);
    };
    subtest "ret_inout" => sub {
        $obj->is("ret_inout")->add_event_listener(sub {
            is $_[1], "value";
            return 1;
        });
        is $obj->is("ret_inout")->call("value"), 111;
        $obj->is->remove_all;
        done_testing(2);
    };
    subtest "ret_arg_inout" => sub {
        $obj->is("ret_arg_inout")->add_event_listener(sub {
            is $_[1], "value custom_in custom_out";
            return 1;
        });
        is $obj->is("ret_arg_inout")->call("value"), 111;
        $obj->is->remove_all;
        done_testing(2);
    };
};

subtest "front/back" => sub {
    my @check;
    my $sub1 = sub { push @check, 1; my $e = shift; $e->(@_) };
    my $sub2 = sub { push @check, 2; my $e = shift; $e->(@_) };
    
    $obj->vv->add_event_listener($sub1);
    $obj->vv->add_event_listener($sub2);
    $obj->vv->call;
    cmp_deeply(\@check, [1,2]);
    $obj->vv->remove_all;
    @check = ();
    
    $obj->vv->add_event_listener($sub1);
    $obj->vv->prepend_event_listener($sub2);
    $obj->vv->call;
    cmp_deeply(\@check, [2,1]);
    $obj->vv->remove_all;
};

subtest "no typemap" => sub {
    $obj->notm->add_event_listener(sub {
        my ($e, $val) = @_;
        is $val, "Xio";
        $val = $e->($val);
        is $val, "Xioioio";
        return $val;
    });
    $obj->notm->add_event_listener(sub {
        my ($e, $val) = @_;
        is $val, "Xioio";
        return $val;
    });
    is $obj->notm->call("X"), "Xioioioio";
    $obj->notm->remove_all;
    done_testing(4);
};

subtest "const ref argument" => sub {
    $obj->viref->add(sub {
        my ($v) = @_;
        is $v, 42;
    });
    $obj->viref->call(42);
    done_testing(1);
};

subtest "add_weak" => sub {
    subtest "basic" => sub {
        {
            package MyCDWeakTest;
            our $dcnt = 0;
            
            sub DESTROY { $dcnt++ }
        }
        
        my $obj = MyTest::DispatchingObject->new;
        my $test = bless {obj => $obj, val => 111}, 'MyCDWeakTest';
        my $d = $obj->vv;
        my ($var, $ccnt);
        $d->add_weak($test, sub {
            $var = $test->{val};
            $ccnt++;
        });
        is $MyCDWeakTest::dcnt, 0;
        
        $d->call;
        
        is $MyCDWeakTest::dcnt, 0;
        is $ccnt, 1;
        is $var, 111, "captured value is correct";
        ok $test;
        
        $test = undef; # $obj and dispatcher still alive
        $var = undef;
        $ccnt = 0;
        
        is $MyCDWeakTest::dcnt, 1, "callback does not hold the object";
        $d->call;
        is $ccnt, 0, "callback wasn't invoked";
    };
    
    subtest "remove callback" => sub {
        my $obj = MyTest::DispatchingObject->new;
        my $cb = sub {$obj};
        $obj->vv->add_weak($obj, $cb);
        ok $obj->vv->has_listeners;
        $obj->vv->remove($cb);
        ok !$obj->vv->has_listeners;
    };
    
    subtest "bad" => sub {
        my $obj = MyTest::DispatchingObject->new;
        my $d = $obj->vv;
        dies_ok { $d->add_weak(undef, sub {}) } "undef payload is not accepted";
        dies_ok { $d->add_weak($obj, undef) } "undef callback is not accepted";
        dies_ok { my $a = 132; $d->add_weak($a, sub {$a}) } "non-refs are not allowed";
        dies_ok { $d->add_weak($obj, sub {}) } "callback must capture the object";
        dies_ok { $d->add_weak($obj, sub {$d}) } "callback must capture the object";
    };
    
    subtest "op_free check" => sub {
        my $obj = MyTest::DispatchingObject->new;
        my $d = $obj->vv;
        my $sub = eval "sub { \$obj }";
        $d->add_weak($obj, $sub);
        $d->remove_all;
        $sub = undef; # all opcodes should be freed now
        pass();
    };
    
    subtest "adding different CV with the same CvSTART" => sub {
        my $obj = MyTest::DispatchingObject->new;
        my $d = $obj->vv;
        my $cnt = 0;
        my $ref = {};
        $d->add_weak($ref, sub {$cnt++; $ref}) for 1..3;
        $d->call;
        $ref = undef;
        $d->call;
        is $cnt, 3;
    };
    
    subtest "remove" => sub {
        my $obj = MyTest::DispatchingObject->new;
        my $d = $obj->vv;
        my $cnt = 0;
        my $sub = sub {$cnt++; $obj};
        $d->add_weak($obj, $sub);
        $d->call;
        $d->remove($sub);
        $d->call;
        is $cnt, 1;
    };
    
    if (0) {
        say "leak check for op_free";
        my $obj = MyTest::DispatchingObject->new;
        my $d = $obj->vv;
        while (1) {
            my $sub = eval "sub { \$obj }";
            $d->add_weak($obj, $sub);
            $d->remove_all;
        }
    }
    
    if (0) {
        say "leak check with different CV and same start";
        my $obj = MyTest::DispatchingObject->new;
        my $d = $obj->vv;
        while (1) {
            $d->add_weak($obj, sub {$obj});
            $d->remove_all;
        }
    }
    
    if (0) {
        require Benchmark;
        my $obj = MyTest::DispatchingObject->new;
        my $test = bless {obj => $obj}, 'MyCDWeakTest';
        my $d = $obj->vv;
        $d->add_weak($test, sub {$test});
        Benchmark::timethis(-1, sub { $obj->call_vv(1000) });
        
        $d->remove_all;
        Benchmark::timethese(-1, {
            orig_add_remove => sub { $d->add(sub {$test}); $d->remove_all },
            weak_add_remove => sub { $d->add_weak($test, sub {$test}); $d->remove_all },
        });
    }
    
    while (0) {
        my $aaa = {obj => MyTest::DispatchingObject->new};
        $aaa->{obj}->vv->add_weak($aaa, sub {
            $aaa;
        });
        $aaa->{obj}->vv->call();
    }
};

done_testing();
