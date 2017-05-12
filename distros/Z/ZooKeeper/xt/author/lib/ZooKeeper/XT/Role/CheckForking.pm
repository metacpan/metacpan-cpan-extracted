package ZooKeeper::XT::Role::CheckForking;
use Storable qw(freeze thaw);
use ZooKeeper;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;

sub test_reopen :Tests(2) {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );
    my $root_stat = $handle->exists('/');

    my $child_stat;
    if (my $pid = open my($child_out), '-|') {
        my $recv    = join '', <$child_out>;
        $child_stat = thaw($recv);
    } else {
        close $child_out;
        $handle->reopen;
        my $stat = $handle->exists('/');
        print freeze($stat);
        exit 0;
    }
    is_deeply $child_stat, $root_stat, 'child stat after reopen matches previous stat';

    my $parent_stat =  $handle->exists('/');
    is_deeply $parent_stat, $root_stat, 'parent stat after reopen matches previous stat';
}

sub test_child_destructor_afer_fork :Tests(1) {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );
    my $root_stat = $handle->exists('/');

    if (my $pid = fork) {
        waitpid $pid, 0;
    } else {
        exit 0;
    }

    my $parent_stat =  $handle->exists('/');
    is_deeply $parent_stat, $root_stat, 'parent stat after forking matches previous stat';
}

1;
