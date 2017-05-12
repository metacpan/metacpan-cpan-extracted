use strict;
use warnings;
use utf8;
use Test::More;
use Test::SharedFork;

sub do_in_fork {
    my ( $action ) = @_;

    my $pid = fork();

    die $! if !defined $pid;

    if($pid) {
        waitpid($pid, 0) or die $!;
    } else {
        # child
        $action->();
        exit 0;
    }
}

open my $fh, ">", \my $out or die $!;
my $builder = Test::Builder->create;
$builder->output($fh);
$builder->failure_output($fh);
$builder->todo_output($fh);

Test::SharedFork::_mangle_builder($builder);

ok $builder->is_passing, 'Test::Builder->is_passing starts truthy';

do_in_fork(sub {
    $builder->ok(1);
});

ok $builder->is_passing, 'Test::Builder->is_passing should still be truthy after a passing test';

do_in_fork(sub {
    $builder->ok(0);
});
ok !$builder->is_passing, 'Test::Builder->is_passing should be falsy after a failing test';

do_in_fork(sub {
    $builder->ok(1);
});

ok !$builder->is_passing, 'Test::Builder->is_passing should still be falsy, even after a passing test post-fail';

diag $out;

done_testing;
