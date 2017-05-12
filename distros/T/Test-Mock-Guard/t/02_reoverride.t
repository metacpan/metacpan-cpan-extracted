use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;

sub new { bless {} => shift }
sub foo { "foo" }

package main;

my $obj = Some::Class->new;
is $obj->foo, 'foo', 'original';

{
    my $guard1 = mock_guard('Some::Class' => { foo => sub { 'xxx' } });
    is $obj->foo, 'xxx', 'guard 1';

    my $guard2 = mock_guard('Some::Class' => { foo => sub { 'yyy' } });
    is $obj->foo, 'yyy', 'guard 2';

    undef $guard2;
}

is $obj->foo, 'foo', 'restored';

{
    my $guard1 = mock_guard('Some::Class' => { foo => sub { 'xxx' } });
    is $obj->foo, 'xxx', 'guard 1';

    my $guard2 = mock_guard('Some::Class' => { foo => sub { 'yyy' } });
    is $obj->foo, 'yyy', 'guard 2';

    undef $guard2;

    is $obj->foo, 'xxx', 'guard 1 restored';
}

is $obj->foo, 'foo', 'restored';

{
    my $guard1 = mock_guard('Some::Class' => { foo => sub { 'xxx' } });
    is $obj->foo, 'xxx', 'guard 1';

    {
        my $guard2 = mock_guard('Some::Class' => { foo => sub { 'yyy' } });
        is $obj->foo, 'yyy', 'guard 2';

        my $guard3 = mock_guard('Some::Class' => { foo => sub { 'zzz' } });
        is $obj->foo, 'zzz', 'guard 3';

        undef $guard2;

        is $obj->foo, 'zzz', 'guard 1 restored';
    }
}

is $obj->foo, 'foo', 'restored';

{
    my $guard1 = mock_guard('Some::Class' => { foo => sub { 'xxx' } });
    is $obj->foo, 'xxx', 'guard 1';

    {
        my $guard2 = mock_guard('Some::Class' => { foo => sub { 'yyy' } });
        is $obj->foo, 'yyy', 'guard 2';

        undef $guard1;

        is $obj->foo, 'yyy', 'guard 1 restored';
    }
}

is $obj->foo, 'foo', 'restored';

{
    my $guard1 = mock_guard('Some::Class' => { foo => sub { 'xxx' } });
    is $obj->foo, 'xxx', 'guard 1';

    my $guard2 = mock_guard('Some::Class' => { foo => sub { 'yyy' } });
    is $obj->foo, 'yyy', 'guard 2';

    my $guard3 = mock_guard('Some::Class' => { foo => sub { 'zzz' } });
    is $obj->foo, 'zzz', 'guard 3';

    undef $guard1;
    undef $guard2;

    is $obj->foo, 'zzz', 'guard 3';
}

is $obj->foo, 'foo', 'restored';

done_testing;
