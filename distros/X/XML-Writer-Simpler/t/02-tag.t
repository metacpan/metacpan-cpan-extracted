#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

use XML::Writer::Simpler;

my $c = 'XML::Writer::Simpler';

sub get_writer {
    my $w = XML::Writer::Simpler->new(OUTPUT => 'self');
}

sub test_tag {
    my @args = @_;
    my $w = get_writer();
    $w->tag(@args);
    throwaway_decl($w->to_string);
}

sub test_nest {
    my ($writer, @args) = @_;
    $writer->tag(@args);
    throwaway_decl($writer->to_string);
}

sub throwaway_decl {
    my ($xml) = shift;
    $xml =~ s/<\?xml version="1\.0" encoding="UTF-8"\?>\s*//s;
    $xml;
}

EMPTY_TAGS: {
    is(test_tag('foo'), '<foo />', 'empty tag');
    is(test_tag('foo', [bar => 'baz']), '<foo bar="baz" />', 'empty tag with attrs');
}

TEXT_TAGS: {
    is(test_tag('foo', 'bar'), '<foo>bar</foo>', 'text tag');
    is(test_tag('foo', [baz => 'quux'], 'bar'),
       '<foo baz="quux">bar</foo>', 'text tag with attrs');
}

NESTED_TAGS: {
    my $w = get_writer();
    is(test_nest($w, 'foo', sub { $w->tag('bar') }),
        '<foo><bar /></foo>', 'nested empty tag');

    $w = get_writer();
    is(test_nest($w, 'foo', [bar => 'baz'], sub { $w->tag('quux') }),
        '<foo bar="baz"><quux /></foo>', 'outer with attrs, inner empty');

    $w = get_writer();
    is(test_nest($w, 'foo', [bar => 'baz'], sub { $w->tag('quux', [bar => 'baz']) }),
        '<foo bar="baz"><quux bar="baz" /></foo>', 'outer with attrs, inner with attrs');

    $w = get_writer();
    is(test_nest($w, 'foo', sub { $w->tag('bar', 'baz') }),
        '<foo><bar>baz</bar></foo>', 'nesting tags recurse');

    $w = get_writer();
    is(test_nest($w, 'foo', sub { $w->tag('bar', [baz => 'quux'], 'foo2') }),
        '<foo><bar baz="quux">foo2</bar></foo>', 'nesting tags recurse with attrs');

    $w = get_writer();
    is(test_nest($w, 'foo', sub { $w->tag('bar', sub { $w->tag('baz') }) }),
        '<foo><bar><baz /></bar></foo>', 'nesting deeply');
}

DIES: {
    my $w = get_writer();
    dies_ok { $w->tag() } 'dies with no tag name';
}


done_testing();
