package cPanel::FakeTasks::A;

# Fake Task processing plugin designed to verify module loading.

sub to_register {
    return ( [ 'donothing' => sub { } ] );
}

1;
