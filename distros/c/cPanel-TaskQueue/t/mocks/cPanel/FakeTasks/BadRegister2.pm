package cPanel::FakeTasks::BadRegister2;

# Fake task processing plugin designed to test error handling.

sub to_register {
    return ( [ 'badcmd' ] );
}

1;

