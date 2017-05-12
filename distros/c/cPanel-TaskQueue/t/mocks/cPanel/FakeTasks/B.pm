package cPanel::FakeTasks::B;

# Fake Task processing plugin designed to verify module loading.

sub to_register {
    return ( [ 'helloworld', sub { print "Hello, World\n"; }, ],
             [ 'hello', sub { print "Hello, @_\n" }, ],
    );
}

1;
