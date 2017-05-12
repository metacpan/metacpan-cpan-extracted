package cPanel::ExampleTasks::Greetings;

# Fake Task processing plugin designed to verify module loading.

sub to_register {
    return ( [ 'helloworld', sub { local $|=1; print "Hello, World\n"; }, ],
             [ 'hello', sub { local $|=1; print "Hello, @_\n"; sleep 1; }, ],
    );
}

1;
