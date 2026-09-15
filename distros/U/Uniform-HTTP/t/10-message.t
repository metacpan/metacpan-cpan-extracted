use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Message;

my $message = Uniform::HTTP::Message->new(
    version => '1.1',
    headers => [
        [ 'X-First',    'one' ],
        [ 'Set-Cookie', 'a=1' ],
        [ 'set-cookie', 'b=2' ],
        [ 'X-Last',     'four' ],
    ],
    body => '',
);

is $message->version, '1.1', 'version is retained without an HTTP prefix';
is $message->header_count, 4, 'field occurrences are counted';
is $message->header('SET-cookie'), 'a=1', 'header returns first occurrence';
is_deeply $message->header_values('Set-Cookie'), [ 'a=1', 'b=2' ],
    'header_values preserves duplicate values in order';
is $message->header_name(2), 'set-cookie', 'original field spelling is retained';
is $message->header_value(2), 'b=2', 'indexed value is retained';
is $message->header_name(50), undef, 'out-of-range index returns undef';
ok $message->headers_are_lossless, 'canonical headers are lossless';
ok $message->has_buffered_body, 'empty body is still a buffered body';
is $message->body, '', 'empty buffered body is returned';
ok $message->is_complete, 'canonical message is complete';
ok $message->is_mutable, 'canonical message is mutable';

is $message->header('Set-Cookie', 'c=3'), $message,
    'header setter is chainable';
is_deeply $message->header_values('set-cookie'), ['c=3'],
    'header setter replaces every occurrence';
is_deeply [ map { $message->header_name($_) } 0 .. $message->header_count - 1 ],
    [ 'X-First', 'Set-Cookie', 'X-Last' ],
    'replacement occupies the first matching position';

is $message->add_header('X-First', 'two'), $message,
    'add_header is chainable';
is_deeply $message->header_values('x-first'), [ 'one', 'two' ],
    'add_header appends a duplicate occurrence';
is $message->remove_header('X-FIRST'), $message,
    'remove_header is chainable';
is_deeply $message->header_values('x-first'), [],
    'remove_header removes every occurrence';

is $message->version(2), $message, 'version setter is chainable';
is $message->version, '2', 'numeric version is stored as bytes';
is $message->version(undef), $message, 'version can be cleared';
is $message->version, undef, 'cleared version is undef';

my $without_body = Uniform::HTTP::Message->new;
ok !$without_body->has_buffered_body, 'omitted body has no buffer';
is $without_body->body, undef, 'omitted body returns undef';
is $without_body->body('bytes'), $without_body, 'body setter is chainable';
ok $without_body->has_buffered_body, 'body setter installs a buffer';

{
    package Local::ImmutableMessage;
    use parent 'Uniform::HTTP::Message';
    sub lock { $_[0]{locked} = 1; return $_[0] }
    sub is_mutable { return $_[0]{locked} ? 0 : 1 }
}

my $immutable = Local::ImmutableMessage->new(
    headers => [ [ 'X-Test', 'before' ] ],
)->lock;
eval { $immutable->header('X-Test', 'after') };
like $@, qr/message is immutable/, 'immutable implementation rejects mutation';
is $immutable->header('X-Test'), 'before', 'failed mutation changes nothing';

done_testing;
