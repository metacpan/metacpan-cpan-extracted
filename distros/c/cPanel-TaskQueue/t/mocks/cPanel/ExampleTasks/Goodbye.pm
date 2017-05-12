package cPanel::ExampleTasks::Goodbye;

# Fake Task processing plugin designed to verify module loading.

{
    package cPanel::ExampleTasks::Farewell;
    use base 'cPanel::TaskQueue::ChildProcessor';

    sub _do_child_task {
        my ($self, $task) = @_;

        my @args = $task->args();
        if ( 1 == @args ) {
            print "Goodbye, $args[0], old friend.\n";
            sleep 2;
            return;
        }
        foreach my $friend ( @args ) {
            print "Farewell, $friend.\n";
            sleep 1;
        }
        print "Farewell to all.\n";
        return;
    }
}

sub to_register {
    return (
        [ 'bye', sub { print "Goodbye, @_\n" }, ],
        [ 'adios', cPanel::ExampleTasks::Farewell->new() ],
    );
}

1;

