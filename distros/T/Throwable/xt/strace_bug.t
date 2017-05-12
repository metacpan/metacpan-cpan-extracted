#!perl
use strict;
use warnings;

use Test::More;

{
    package My::Trace;
    sub new { bless {} }
    sub as_string { '' }
}

{
    package My::X;
    use Moose;
    with(
        'Throwable',
        'StackTrace::Auto',
    );

    has message              => ( is      => 'ro' );
    has '+stack_trace_class' => ( builder => 'tclass' );
    sub tclass { 'My::Trace' }
}

eval {
    eval "die 'Previously'" or My::X->throw(message => 'WTF!');
};
my $error = $@;
is $error->message, 'WTF!', 'Should have message';
like $error->previous_exception, qr/Previously/, 'Should have previous exception';
isa_ok $error->stack_trace_class, 'My::Trace';

done_testing();

