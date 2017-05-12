package cPanel::FakeTasks::C;

# Fake Task processing plugin designed to verify module loading.

sub to_register {
    return (
        [ 'bye', sub { print "Goodbye, @_\n" }, ],
    );
}

1;

