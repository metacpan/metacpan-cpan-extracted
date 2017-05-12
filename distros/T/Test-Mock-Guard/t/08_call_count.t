use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;

sub new { bless {} => shift }
sub foo { "foo" }
sub bar { 1; }
sub baz { "baz" }

package main;

{
    for (1..3) {
        # class
        my $counts = { foo => 1, bar => 10, baz => 0 };
        my $guard = mock_guard('Some::Class' => $counts);
        my $obj = Some::Class->new;

        for my $name (keys %$counts) {
            is $guard->call_count('Some::Class', $name), 0;
        }

        for my $name (keys %$counts) {
            my $count = $counts->{$name};
            for (1..$count) {
                is $obj->$name => $count;
            }

            is $guard->call_count('Some::Class', $name) => $count;
        }
    }
}

{
    for (1..3) {
        # object
        my $counts = { foo => 1, bar => 10, baz => 0 };
        my $obj = Some::Class->new;
        my $guard = mock_guard($obj => $counts);

        for my $name (keys %$counts) {
            is $guard->call_count($obj, $name), 0;
        }

        for my $name (keys %$counts) {
            my $count = $counts->{$name};
            for (1..$count) {
                is $obj->$name => $count;
            }

            is $guard->call_count($obj, $name) => $count;
        }
    }
}

{

    for (1..3) {
        # not mocked object
        my $obj = Some::Class->new;
        my $counts = { foo => 1, bar => 10, baz => 0 };
        my $guard = mock_guard('Some::Class' => $counts);

        for my $name (keys %$counts) {
            is $guard->call_count($obj, $name), undef;
        }
    }
}

done_testing;
