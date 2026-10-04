use strict;
use warnings;
use Test::More;
use Uniform::HTTP::Message;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

for my $case (
    [ 'Uniform::HTTP::Message' ],
    [ 'Uniform::HTTP::Request', method => 'POST', target => '/' ],
    [ 'Uniform::HTTP::Response', status => 200 ],
) {
    my ($class, @args) = @$case;
    subtest $class => sub {
        for my $extra ([], [ trailers => [] ]) {
            my $empty = $class->new(@args, @$extra);
            is $empty->has_trailers, 0, 'no fields, including explicit empty section';
            is $empty->trailer_count, 0, 'zero occurrences';
            is $empty->trailer('X-Test'), undef, 'absent value';
            is_deeply $empty->trailer_values('X-Test'), [], 'absent values';
            is $empty->trailer_name(0), undef, 'no indexed name';
            is $empty->trailer_value(0), undef, 'no indexed value';
            ok $empty->trailers_are_lossless, 'known empty section is lossless';
        }
        my $input = [
            [ 'X-First', 'one' ], [ 'X-Metric', 'a,b' ],
            [ 'x-metric', "\t\x80\xff " ], [ 'X-Last', '' ],
        ];
        my $m = $class->new(@args,
            headers => [ [ 'X-Metric', 'initial' ], [ 'Trailer', 'X-Metric' ] ],
            trailers => $input);
        $input->[0][1] = 'changed';
        push @$input, [ 'X-Extra', 'changed' ];
        is $m->trailer_count, 4, 'constructor copies outer array';
        is $m->trailer_value(0), 'one', 'constructor copies pairs';
        is $m->trailer('X-METRIC'), 'a,b', 'case-insensitive first occurrence';
        is_deeply $m->trailer_values('x-metric'), [ 'a,b', "\t\x80\xff " ],
            'duplicates, commas, whitespace, and high bytes preserved';
        is $m->trailer_name(2), 'x-metric', 'source spelling';
        is $m->trailer_value(3), '', 'empty field value';
        ok $m->has_trailers, 'fields present';
        is $m->header('X-Metric'), 'initial', 'header lookup excludes trailers';
        is $m->trailer('Trailer'), undef, 'trailer lookup excludes headers';
        is $m->header_count, 2, 'initial count excludes trailers';
        my $values = $m->trailer_values('X-Metric');
        $values->[0] = 'changed';
        is $m->trailer('X-Metric'), 'a,b', 'returned values are detached';
        is $m->trailer('x-METRIC', 'replacement'), $m, 'replacement is chainable';
        is_deeply [ map { $m->trailer_name($_) } 0 .. $m->trailer_count - 1 ],
            [ 'X-First', 'x-METRIC', 'X-Last' ], 'replacement keeps first position';
        is_deeply $m->trailer_values('X-Metric'), ['replacement'], 'all duplicates replaced';
        is $m->add_trailer('X-Metric', 'last'), $m, 'append is chainable';
        is $m->trailer_value(3), 'last', 'append goes last';
        is $m->remove_trailer('X-METRIC'), $m, 'removal is chainable';
        is_deeply [ map { $m->trailer_name($_) } 0 .. $m->trailer_count - 1 ],
            [ 'X-First', 'X-Last' ], 'remove preserves other order';
        is $m->remove_trailer('Missing'), $m, 'absent removal is harmless';
        is $m->trailer('X-New', 'new'), $m, 'setter appends absent field';
        is $m->trailer_name(2), 'X-New', 'absent setter goes last';
        is $m->header('X-Metric'), 'initial', 'trailer mutations never alter headers';
    };
}

sub rejects {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    ok !$ok && $@ =~ $pattern, $label or diag $@ || 'unexpected success';
}

for my $bad (undef, {}, 'text', [undef], [[]], [['X']], [['X', 'v', 'extra']]) {
    rejects(sub { Uniform::HTTP::Message->new(trailers => $bad) },
        qr/array reference/, 'malformed trailer constructor rejected');
}
for my $bad (undef, [], '', 'bad name', ':status', "X\xff", chr(256)) {
    rejects(sub { Uniform::HTTP::Message->new(trailers => [[$bad, 'v']]) },
        qr/trailer name/, 'invalid trailer name rejected');
}
my $m = Uniform::HTTP::Message->new(trailers => [['X-Test', 'before']]);
for my $bad (undef, [], chr(256), map { chr($_) } (0 .. 8, 10 .. 31, 127)) {
    for my $method (qw(trailer add_trailer)) {
        rejects(sub { $m->$method('X-Test', $bad) }, qr/trailer value/,
            "$method rejects invalid value");
        is_deeply $m->trailer_values('X-Test'), ['before'], 'failed mutation is atomic';
    }
    rejects(sub { Uniform::HTTP::Message->new(trailers => [['X', $bad]]) },
        qr/trailer value/, 'constructor rejects invalid value');
}
my $latin1 = "\xff";
utf8::upgrade($latin1);
$m->add_trailer('X-Bytes', $latin1);
is $m->trailer('X-Bytes'), "\xff", 'byte-valued Unicode scalar accepted without encoding';
ok !utf8::is_utf8($m->trailer('X-Bytes')), 'stored as bytes';
ok utf8::is_utf8($latin1), 'caller scalar left alone';
for my $bad (undef, [], -1, 0.5, '1x', ' 1') {
    for my $method (qw(trailer_name trailer_value)) {
        rejects(sub { $m->$method($bad) }, qr/non-negative integer/, 'invalid index rejected');
    }
}
for my $method (qw(trailer_name trailer_value)) {
    is $m->$method(999), undef, 'out-of-range index is undef';
}
for my $call (
    [trailer => []], [trailer => ['X', 'v', 'extra']],
    [trailer_values => []], [trailer_values => ['X', 'Y']],
    [add_trailer => ['X']], [remove_trailer => []],
    [remove_trailer => ['X', 'Y']], [trailer_name => []],
    [trailer_value => [0, 1]], [trailer_count => [1]],
    [has_trailers => [1]], [trailers_are_lossless => [1]],
) {
    my ($method, $args) = @$call;
    rejects(sub { $m->$method(@$args) }, qr/\Q$method\E\(\)/, "$method checks arity");
}
done_testing;
