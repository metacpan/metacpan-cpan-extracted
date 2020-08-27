use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

my $RUNS = 3;

sub test_call(&) {
    my $code = shift;
    my $m1 = MyTest::marker();
    $code->();
    my $m2 = MyTest::marker();
    my $d = $m2 - ($m1 + 2);
    return $d;
}

subtest 'logXXXX optimizations' => sub {
    my $ctx = Context->new;
    XLog::set_level(XLog::INFO);

    subtest '0 args' => sub {
        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::debug() for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::warn() for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '0 args (goto, not optimized)' => sub {
        my $count = $ctx->cnt;
        subtest 'not-logged' => sub {
            my $fn = 'XLog'->can('debug');
            my $cnt = test_call(sub {
                (goto &$fn) for(1..$RUNS);
            });
            is $cnt, 0;
            is $ctx->cnt, $count;
        };

        subtest 'logged' => sub {
            my $fn = 'XLog'->can('warn');
            my $cnt = test_call(sub {
                (goto &$fn) for(1..$RUNS);
            });
            is $cnt, 0;
            is $ctx->cnt, $count + 1;
        };
    };

    subtest '0 args (opf_stacked)' => sub {
        my $count = $ctx->cnt;
        subtest 'not-logged' => sub {
            my $ref = 'XLog'->can('debug');
            my $fn = sub { &$ref };
            my $cnt = test_call(sub {
                $fn->() for(1..$RUNS);
            });
            is $cnt, $RUNS + 1;
        };

        subtest 'logged' => sub {
            my $ref = 'XLog'->can('warn');
            my $fn = sub { &$ref };
            my $cnt = test_call(sub {
                $fn->() for(1..$RUNS);
            });
            is $cnt, $RUNS * 2;
        };
    };

    subtest '1 arg, our mesasge' => sub {
        our $message = "hi";
        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::debug($message) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::warn($message) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 arg, dynamic message, unoptimized' => sub {
        my $c = 0;
        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::debug("@{[ ++$c ]}") for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::warn("@{[ ++$c ]}") for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 arg, module' => sub {
        my $mod = XLog::Module->new("mymod");
        $mod->level(XLog::INFO);
        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::debug($mod) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::warn($mod) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest 'module + message' => sub {
        my $c = 0;
        my $mod = XLog::Module->new("mymod");
        $mod->level(XLog::INFO);

        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::debug($mod, ++$c) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::warn($mod, ++$c) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 arg is function call, not optimized' => sub {
        my $get_message = sub { "hi" };
        my $cnt = test_call(sub {
            XLog::debug($get_message->()) for(1..$RUNS);
        });
        is $cnt, $RUNS * 2;
    };

    subtest 'condvar is not optimized' => sub {
        my $get_message = sub { "hi" };
        my $cnt = test_call(sub {
            XLog::debug(rand > 0.5 ? 10 : 20) for(1..$RUNS);
        });
        is $cnt, $RUNS;
    };
};

subtest 'low-level log($level, ...) optimizations' => sub {
    my $ctx = Context->new;
    XLog::set_level(XLog::INFO);

    subtest '1 level arg (const)' => sub {
        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::DEBUG) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::WARNING) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 level arg (padsv)' => sub {
        subtest 'not-logged' => sub {
            my $l = XLog::DEBUG;
            my $cnt = test_call(sub {
                XLog::log($l) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $l = XLog::WARNING;
            my $cnt = test_call(sub {
                XLog::log($l) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 level arg (our)' => sub {
        subtest 'not-logged' => sub {
            our $l = XLog::DEBUG;
            my $cnt = test_call(sub {
                XLog::log($l) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            our $l = XLog::WARNING;
            my $cnt = test_call(sub {
                XLog::log($l) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 level arg (const) + message' => sub {
        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::DEBUG, "hi") for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::WARNING, "hi") for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 level arg (const) + module (padsv)' => sub {
        my $mod = XLog::Module->new("mymod");
        $mod->level(XLog::INFO);

        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::DEBUG, $mod) for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::WARNING, $mod) for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };

    subtest '1 level arg (const) + module (padsv) + message' => sub {
        my $mod = XLog::Module->new("mymod");
        $mod->level(XLog::INFO);

        subtest 'not-logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::DEBUG, $mod, "hi") for(1..$RUNS);
            });
            is $cnt, 1;
        };

        subtest 'logged' => sub {
            my $cnt = test_call(sub {
                XLog::log(XLog::WARNING, $mod, "hi") for(1..$RUNS);
            });
            is $cnt, $RUNS;
        };
    };
};

subtest "no crashes on wrong args" => sub {
    my $ctx = Context->new;
    XLog::set_level(XLog::INFO);


    SKIP: {
        my $ok = eval "use Capture::Tiny qw/:all/; 1";
        skip ('Capture::Tiny is required', 1) unless $ok;

        Capture::Tiny::capture_stderr(sub {
            subtest 'wrong level arg' => sub {
                my $sub = sub {
                    my $level = shift;
                    XLog::log($level);
                };

                $sub->(XLog::DEBUG);    # warm-up

                my $cnt = test_call(sub {
                    for(1..$RUNS) {
                        eval { $sub->('i-go-go') };
                    }
                });
                is $cnt, $RUNS;
            };
         });
    };

    subtest 'wrong module arg' => sub {
        my $mod = XLog::Module->new("mymod");
        $mod->level(XLog::INFO);
        my $sub = sub {
            my ($level, $module) = @_;
            XLog::log($level, $module);
        };

        $sub->(XLog::INFO, $mod);    # warm-up

        my $fake_mod = bless {} => 'XLog::Module';
        our $xlog_module = $mod;
        my $cnt = test_call(sub {
            for(1..$RUNS) {
                eval { $sub->(XLog::INFO, $fake_mod) };
            }
        });
        is $cnt, $RUNS;
    };
};

done_testing;
