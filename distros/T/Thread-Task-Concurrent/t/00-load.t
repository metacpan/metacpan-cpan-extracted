#!perl -T

use Test::More;

BEGIN {
    use Config;

    use_ok('Thread::Task::Concurrent::Util') || print "Bail out!";
    use_ok('Thread::Task::Concurrent')       || print "Bail out!";
}

diag("Testing Thread::Task::Concurrent::Util $Thread::Task::Concurrent::Util::VERSION, Perl $], $^X");
diag("Testing Thread::Task::Concurrent $Thread::Task::Concurrent::VERSION, Perl $], $^X");

done_testing();
