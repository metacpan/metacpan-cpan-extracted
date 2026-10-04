use strict;
use warnings;
use Test::More;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

for my $case (
    ['Uniform::HTTP::Request', [method => 'CONNECT', target => '/chat', protocol => 'websocket'],
        [[method => 'POST'], [target => '/other'], [scheme => 'https'],
         [authority => 'example.com'], [protocol => 'connect-udp'], [protocol => undef]]],
    ['Uniform::HTTP::Response', [status => 200], [[status => 404], [reason => 'Other']]],
) {
    my ($class, $args, $specific) = @$case;
    subtest $class => sub {
        my $m = $class->new(@$args, headers => [['X-State', 'initial']]);
        my @initial = (@$specific, [version => '3'], [version => undef],
            [header => 'X-State', 'new'], [add_header => 'X-New', 'new'],
            [remove_header => 'X-State']);
        my @trailers = ([trailer => 'X-Metric', 'new'],
            [add_trailer => 'X-Metric', 'new'], [remove_trailer => 'X-Metric']);
        ok $m->is_complete, 'detached object starts complete';
        is $m->mark_incomplete, $m, 'mark_incomplete chainable';
        is $m->freeze_initial, $m, 'freeze_initial chainable';
        is $m->freeze_initial, $m, 'freeze_initial idempotent';
        ok !$m->is_complete, 'initial freeze does not complete message';
        ok $m->is_mutable, 'some data can still change';
        ok !$m->initial_is_mutable, 'initial section is fixed';
        ok $m->body_is_mutable, 'buffer can still be supplied';
        ok $m->trailers_are_mutable, 'late trailers can arrive';
        for my $call (@initial) {
            my ($method, @values) = @$call;
            eval { $m->$method(@values) };
            like $@, qr/initial message data is immutable/, "$method blocked by initial freeze";
        }
        is $m->header('X-State'), 'initial', 'initial data unchanged';
        is $m->body, undef, 'reading incomplete message does not invent body';
        ok !$m->has_buffered_body, 'external streaming not a buffer';
        is $m->body("all body bytes\0\xff"), $m, 'complete buffer installed after initial freeze';
        is $m->add_trailer('X-Metric', 'one'), $m, 'late trailer accepted';
        $m->add_trailer('x-metric', 'two');
        is_deeply $m->trailer_values('X-Metric'), ['one', 'two'], 'late duplicates preserved';
        is $m->mark_complete, $m, 'completion is chainable';
        ok $m->is_complete, 'complete includes externally finished trailers';
        ok !$m->initial_is_mutable, 'completion does not thaw initial data';
        ok $m->trailers_are_mutable, 'completion is not an implicit freeze';
        $m->add_trailer('X-Local', 'edited');
        is $m->freeze_trailers, $m, 'freeze_trailers chainable';
        is $m->freeze_trailers, $m, 'freeze_trailers idempotent';
        ok !$m->trailers_are_mutable, 'trailer section fixed';
        ok $m->body_is_mutable, 'trailer freeze leaves buffer mutable';
        for my $call (@trailers) {
            my ($method, @values) = @$call;
            eval { $m->$method(@values) };
            like $@, qr/trailers are immutable/, "$method blocked by trailer freeze";
        }
        $m->mark_incomplete;
        ok !$m->trailers_are_mutable, 'mark_incomplete does not thaw trailers';
        $m->freeze;
        $m->freeze_initial->freeze_trailers;
        for my $method (qw(is_mutable initial_is_mutable body_is_mutable trailers_are_mutable)) {
            ok !$m->$method, "$method false after full freeze";
        }
        for my $call (@initial, @trailers, [body => 'changed']) {
            my ($method, @values) = @$call;
            eval { $m->$method(@values) };
            like $@, qr/message is immutable/, "$method blocked by full freeze";
        }
        is $m->body, "all body bytes\0\xff", 'freeze preserves body';
        is $m->trailer_count, 3, 'freeze preserves trailers';
        $m->mark_complete;
        ok $m->is_complete, 'completion can advance after full freeze';
        $m->mark_incomplete;
        ok !$m->is_complete, '0.03 completeness helper still works after freeze';
        ok !$m->trailers_are_mutable, 'completeness changes cannot thaw';

        my $empty = $class->new(@$args)->freeze_trailers;
        ok !$empty->has_trailers, 'empty trailer section may be frozen';
        ok $empty->initial_is_mutable, 'trailer-only freeze leaves initial data open';
        $empty->header('X-Late-Initial', 'ok');
        eval { $empty->add_trailer('X', 'v') };
        like $@, qr/trailers are immutable/, 'empty frozen section cannot be extended';

        for my $method (qw(freeze_initial freeze_trailers initial_is_mutable body_is_mutable trailers_are_mutable)) {
            eval { $empty->$method(1) };
            like $@, qr/does not accept arguments/, "$method checks arity";
        }
    };
}
done_testing;
