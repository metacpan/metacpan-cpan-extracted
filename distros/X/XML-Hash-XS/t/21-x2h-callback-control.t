use strict;
use warnings;

use Test::More 0.98;
use XML::Hash::XS qw(
    xml2hash
    XML_HASH_XS_CONTINUE
    XML_HASH_XS_STOP
    XML_HASH_XS_SKIP
);

sub exception;

is(XML_HASH_XS_CONTINUE, 'XML_HASH_XS_CONTINUE', 'CONTINUE constant');
is(XML_HASH_XS_STOP, 'XML_HASH_XS_STOP', 'STOP constant');
is(XML_HASH_XS_SKIP, 'XML_HASH_XS_SKIP', 'SKIP constant');

{
    my @nodes;
    my $result = xml2hash(
        '<root><item>one</item><item>two</item><item>three</item></root>',
        filter => '/root/item',
        keep_root => 0,
        cb => sub {
            push @nodes, $_[0];
            return @nodes == 2 ? XML_HASH_XS_STOP : XML_HASH_XS_CONTINUE;
        },
    );

    ok(!defined $result, 'node callback with STOP has no return value');
    is_deeply(\@nodes, [ 'one', 'two' ], 'STOP ends parsing after the current matched node');
}

for my $stop_at (1, 2, 3) {
    my @nodes;
    xml2hash(
        '<root><item>one</item><item>two</item><item>three</item></root>',
        filter => '/root/item',
        keep_root => 0,
        cb => sub {
            push @nodes, $_[0];
            return @nodes == $stop_at ? XML_HASH_XS_STOP : XML_HASH_XS_CONTINUE;
        },
    );
    is(scalar @nodes, $stop_at, "STOP on match $stop_at");
}

{
    my @nodes;
    my $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        keep_root => 0,
        cb => sub {
            push @nodes, $_[0];
            return XML_HASH_XS_STOP;
        },
    );

    $parser->feed('<root><item>one</item><item>ignored</item></root>');
    is_deeply(\@nodes, [ 'one' ], 'STOP ignores bytes remaining in the current feed');
    like(exception(sub { $parser->feed('<more/>') }), qr/Parser is stopped/, 'feed after STOP is rejected');
    ok(!defined $parser->finish, 'finish after STOP is successful and returns undef');
}

{
    my @nodes;
    xml2hash(
        '<root><item>one</item><item>two</item></root>',
        filter => '/root/item',
        keep_root => 0,
        cb => sub { push @nodes, $_[0]; return; },
    );
    is_deeply(\@nodes, [ 'one', 'two' ], 'legacy one-argument callback remains compatible');
}

{
    my @events;
    my $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        cb_mode => 'events',
        keep_root => 1,
        cb => sub {
            my ($event, $value, $meta) = @_;
            push @events, [ $event, $value, { %$meta } ];
            return XML_HASH_XS_SKIP
                if $event eq 'start' && $meta->{attributes}{type} eq 'skip';
            return XML_HASH_XS_CONTINUE;
        },
    );

    $parser->feed('<root><item type="skip"><item><large>discar');
    $parser->feed('ded</large></item></item><item type="keep">wanted</item></root>');
    ok(!defined $parser->finish, 'event callback parser has no result');

    is_deeply(
        [ map { $_->[0] } @events ],
        [ 'start', 'start', 'end' ],
        'SKIP suppresses end and nested events for the skipped match',
    );
    is($events[0][2]{name}, 'item', 'start metadata contains name');
    is($events[0][2]{path}, '/root/item', 'start metadata contains path');
    is($events[0][2]{depth}, 2, 'start metadata contains depth');
    is($events[0][2]{attributes}{type}, 'skip', 'start metadata contains attributes');
    is_deeply($events[2][1], { item => { type => 'keep', content => 'wanted' } }, 'end receives built node');
}

{
    my @events;
    my $payload = '<branch>' . ('<leaf>discarded</leaf>' x 2000) . '</branch>';
    my $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        cb_mode => 'events',
        cb => sub {
            push @events, $_[0];
            return $_[0] eq 'start' ? XML_HASH_XS_SKIP : XML_HASH_XS_CONTINUE;
        },
    );
    $parser->feed('<root><item>' . $payload . '</item></root>');
    $parser->finish;
    is_deeply(\@events, [ 'start' ], 'large skipped subtree produces no end callback');
}

{
    my $error = exception(sub {
        my $parser = XML::Hash::XS::Parser->new(
            filter => '/root/item',
            cb_mode => 'events',
            cb => sub { die "callback failed\n" },
        );
        $parser->feed('<root><item>one</item></root>');
    });
    like($error, qr/callback failed/, 'event callback exception is propagated');
}

{
    my @events;
    my $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        cb_mode => 'events',
        cb => sub {
            push @events, $_[0];
            return $_[0] eq 'end' ? XML_HASH_XS_STOP : XML_HASH_XS_CONTINUE;
        },
    );
    $parser->feed('<root><item>one</item><item>ignored</item></root>');
    is_deeply(\@events, [ 'start', 'end' ], 'STOP is accepted on end event');
    ok(!defined $parser->finish, 'finish succeeds after event STOP');
}

{
    my $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        cb_mode => 'events',
        cb => sub { return XML_HASH_XS_STOP },
    );
    $parser->feed('<root><item type="first">ignored</item></root>');
    ok(!defined $parser->finish, 'STOP is accepted on start event');
}

{
    my $error = exception(sub {
        xml2hash(
            '<root><item>one</item></root>',
            filter => '/root/item',
            cb => sub { XML_HASH_XS_SKIP },
        );
    });
    like($error, qr/SKIP is valid only for start events/, 'SKIP is rejected in node mode');
}

{
    my $error = exception(sub { XML::Hash::XS::Parser->new(cb_mode => 'invalid') });
    like($error, qr/Invalid parameter value for 'cb_mode'/, 'invalid cb_mode is rejected');
}

{
    my $parser;
    $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        cb => sub { $parser->feed('<recursive/>') },
    );
    like(
        exception(sub { $parser->feed('<root><item>one</item></root>') }),
        qr/Recursive feed/,
        'recursive feed from callback is rejected',
    );
}

done_testing;

sub exception {
    local $@;
    eval { $_[0]->() };
    return $@;
}
