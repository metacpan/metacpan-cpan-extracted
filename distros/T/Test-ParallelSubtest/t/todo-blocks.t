# Interactions between bg_subtest() and TODO blocks

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest whole_bg_subtest_todo => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    bg_subtest bar => sub {
        TODO: {
            local $TODO = 'just because';

            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
        };
        done_testing;
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest whole_bg_subtest_todo_plan => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    bg_subtest bar => sub {
        plan tests => 2;
        TODO: {
            local $TODO = 'just because';

            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest whole_bg_subtest_todo_badplan => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    bg_subtest bar => sub {
        plan tests => 20;
        TODO: {
            local $TODO = 'just because';

            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest whole_bg_subtest_todo_missingplan => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    bg_subtest bar => sub {
        TODO: {
            local $TODO = 'just because';

            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest part_bg_subtest_todo => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    bg_subtest bar => sub {
        ok 1;
        TODO: {
            local $TODO = 'just because';

            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
        };
        done_testing;
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest bg_subtest_in_todo => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    TODO: {
        local $TODO = 'just because';

        bg_subtest a_todo_subtest => sub {
            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
            done_testing;
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest bg_subtest_in_todo_0 => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    TODO: {
        local $TODO = 0;

        bg_subtest a_todo_subtest => sub {
            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
            done_testing;
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest bg_subtest_in_todo_emptystr => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    TODO: {
        local $TODO = '';

        bg_subtest a_todo_subtest => sub {
            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
            done_testing;
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest nested_subtest_in_todo => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    bg_subtest foo => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };

    bg_subtest bar => sub {
        ok 1;
        TODO: {
            local $TODO = 'just because';

            ok 0, 'failing todo test';
            ok 1, 'passing todo test';
            subtest bar => sub {
                ok 1;
                ok 0;
                done_testing;
            };
            done_testing;
        };
    };

    bg_subtest baz => sub {
        ok 0, 'failing test';
        ok 1, 'passing test';
        done_testing;
    };
END

same_as_subtest todo_bg_subtest => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    TODO: {
        local $TODO = 'just because';

        bg_subtest foo => sub {
            ok 0, 'failing test';
            ok 1, 'passing test';
            done_testing;
        };

        bg_subtest bar => sub {
            ok 1;
            subtest bar => sub {
                ok 1;
                ok 0;
                done_testing;
            };
            done_testing;
        };

        bg_subtest baz => sub {
            ok 0, 'failing test';
            ok 1, 'passing test';
            done_testing;
        };
    };
END

same_as_subtest todo_subtest_bg => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    TODO: {
        local $TODO = 'just because';

        subtest outer => sub {
            bg_subtest foo => sub {
                ok 0, 'failing test';
                ok 1, 'passing test';
                done_testing;
            };

            bg_subtest bar => sub {
                ok 1;
                done_testing;
            };

            bg_subtest baz => sub {
                ok 0, 'failing test';
                ok 1, 'passing test';
                done_testing;
            };
            
            done_testing;
        };
    };
END

same_as_subtest todo_subtest_subtest_bg => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    TODO: {
        local $TODO = 'reason';

        subtest foo => sub {
            subtest bar => sub {
                bg_subtest foo => sub {
                    ok 0, 'failing test';
                    ok 1, 'passing test';
                    done_testing;
                };
                done_testing;
            };
            done_testing;
        };
    };
END

same_as_subtest manytodo_subtest_subtest_bg => <<'END';
    use Test::ParallelSubtest;
    use Test::More;

    TODO: { local $TODO = 'level 1';
        subtest foo => sub {
            TODO: { local $TODO = 'level 2';
                subtest bar => sub {
                    TODO: { local $TODO = 'level 3';
                        bg_subtest foo => sub {
                            ok 1, 'foo pass';
                            ok 0, 'foo fail';
                            TODO: { local $TODO = 'level 4';
                                ok 1, 'foo todo pass';
                                ok 0, 'foo todo fail';
                                done_testing;
                            };
                            done_testing;
                        };
                    };
                    bg_subtest bar => sub {
                        ok 0, 'failing test';
                        ok 1, 'passing test';
                        TODO: { local $TODO = 'level 5';
                            ok 1, 'bar todo pass';
                            ok 0, 'bar todo fail';
                        };
                        done_testing;
                    };
                    done_testing;
                };
            };
            done_testing;
        };
    };

    done_testing;
END

same_as_subtest nontodo_reaped_in_todo => <<'END';
    use Test::ParallelSubtest max_parallel => 1;
    use Test::More;

    bg_subtest foo => sub {
        ok 0, "this is a failing live test";
        done_testing;
    };

    TODO: {
        local $TODO = 'now in todo';

        # max_parallel is set to 1, so this will reap the "foo" child
        # before it launches the "bar" child...

        bg_subtest bar => sub {
            ok 0, "this is a failing todo test";
            done_testing;
        };
    };

    done_testing;
END

same_as_subtest nontodo_reaped_in_todo => <<'END';
    use Test::ParallelSubtest max_parallel => 1;
    use Test::More;

    bg_subtest foo => sub {
        ok 0, "this is a failing live test";
        done_testing;
    };

    TODO: {
        local $TODO = 'now in todo';

        # max_parallel is set to 1, so this will reap the "foo" child
        # before it launches the "bar" child...

        bg_subtest bar => sub {
            ok 0, "this is a failing todo test";
            done_testing;
        };
    };

    done_testing;
END

same_as_subtest todo_reaped_in_other_todo => <<'END';
    use Test::ParallelSubtest max_parallel => 1;
    use Test::More;

    TODO: {
        local $TODO = 'todo1';

        bg_subtest foo => sub {
            ok 0, "this is a failing todo1 test";
            done_testing;
        };
    };

    TODO: {
        local $TODO = 'todo2';

        # max_parallel is set to 1, so this will reap the "foo" child
        # before it launches the "bar" child...

        bg_subtest bar => sub {
            ok 0, "this is a failing todo2 test";
            done_testing;
        };
    };

    done_testing;
END

done_testing;
