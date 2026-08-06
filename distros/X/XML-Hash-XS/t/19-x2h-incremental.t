use strict;
use warnings;

use Test::More 0.98;
use XML::Hash::XS qw();

sub exception;

my $xml = '<root><item id="1">one &amp; two</item><item id="2">three</item></root>';
my $expected = {
    root => {
        item => [
            { id => '1', content => 'one & two' },
            { id => '2', content => 'three' },
        ],
    },
};

for my $at (0 .. length $xml) {
    my $parser = XML::Hash::XS::Parser->new(keep_root => 1);
    $parser->feed(substr($xml, 0, $at));
    $parser->feed(substr($xml, $at));
    is_deeply($parser->finish, $expected, "split at byte $at");
}

{
    my $parser = XML::Hash::XS::Parser->new(keep_root => 1);
    $parser->feed($_) for split //, $xml;
    is_deeply($parser->finish, $expected, 'one byte at a time');
}

{
    my $chunk = '<root><a>value</a></root>';
    my $parser = XML::Hash::XS::Parser->new(keep_root => 1);
    $parser->feed(\$chunk);
    is_deeply($parser->finish, { root => { a => 'value' } }, 'scalar reference chunk');
}

{
    my @got;
    my $parser = XML::Hash::XS::Parser->new(
        filter => '/root/item',
        keep_root => 1,
        cb => sub { push @got, $_[0] },
    );
    $parser->feed('<root><item>one</item>');
    $parser->feed('<item>two</item></root>');
    ok(!defined $parser->finish, 'callback parser has no result');
    is_deeply(
        \@got,
        [ { item => 'one' }, { item => 'two' } ],
        'callback receives nodes across chunks',
    );
}

{
    my $parser = XML::Hash::XS::Parser->new;
    $parser->feed('<root>');
    like(exception(sub { $parser->finish }), qr/Invalid XML/, 'finish rejects unfinished XML');
    like(exception(sub { $parser->feed('</root>') }), qr/failed state/, 'feed after parsing error is rejected');
}

{
    my $parser = XML::Hash::XS::Parser->new;
    $parser->feed('<root/>');
    $parser->finish;
    like(exception(sub { $parser->finish }), qr/already finished/, 'finish is single-use');
    like(exception(sub { $parser->feed('') }), qr/already finished/, 'feed after finish is rejected');
}

done_testing;

sub exception {
    local $@;
    eval { $_[0]->() };
    return $@;
}
