[![Build Status](https://travis-ci.org/hatena/Test-Time-At.svg?branch=master)](https://travis-ci.org/hatena/Test-Time-At)
# NAME

Test::Time::At - Do a test code, specifying the time

# SYNOPSIS

    use Test::Time time => 1;
    use Test::Time::At;
    use Test::More;

    my $now = time; # $now is equal to 1 (by Test::Time)

    do_at {
        my $now_in_this_scope = time; # $now_in_this_scope is equal to 1000
        sleep 100; # returns immediately
        my $then_in_this_scope = time; # $then_in_this_scope is equal to 1100
    } 1000;

    my $then = time; # After do_at, time is equal to 1 again

# DESCRIPTION

Test::Time::At supports to specify the time to do a test code.  You have to use [Test::Time](https://metacpan.org/pod/Test::Time) with this module.

# METHODS

## do\_at(&$)

Do a code at specifying epoch time.  You can specify the instance which has the method named 'epoch'.

    # You can specify epoch time
    do_at {
        my $now = time
    } 1000;

    # You can also specify the instance, for example Time::Piece and DateTime
    do_at {
        my $now = time
    } DateTime->new(year => 2015, month => 8, day => 10);

    do_at {
        my $now = time
    } Time::Piece->strptime('2015-08-10T06:29:10', '%Y-%m-%dT%H:%M:%S');

## sub\_at(&$)

sub\_at is useful if you want to specify the time for subtest.  this prevents the nest from becoming deeper.

    subtest 'I want to this subtest on Aug. 10, 2015' => sub_at {
        my $now = time;
    } DateTime->new(year => 2015, month => 8, day => 10);

# SEE ALSO

[Test::Time](https://metacpan.org/pod/Test::Time)

# LICENSE

Copyright (C) shibayu36.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

shibayu36 &lt;shibayu36@gmail.com>

nanto\_vi (TOYAMA Nao) &lt;nanto@moon.email.ne.jp>
