package cPanel::FakeTasks::BadRegister;

# Fake task processing plugin designed to test error handling.

sub to_register {
    return qw/a b c d/;
}

1;
