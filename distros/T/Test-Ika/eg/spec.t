use strict;
use warnings;
use utf8;
use lib 'lib';
use Test::Ika;
use Test::More;

{
    package MessageFilter;
    sub new {
        my ($class, $word) = @_;
        bless \$word, $class;
    }
    sub detect {
        my ($self, $str) = @_;
        return index($str, $$self) >= 0;
    }
}

describe 'foo' => sub {
    describe 'bar' => sub {
        die "Oops";
    };
};

describe 'MessageFilter' => sub {
    my $filter;
    before_each {
        $filter = MessageFilter->new('foo');
    };

    it 'should detect message with NG word' => sub {
        ok($filter->detect('hello from foo'));
    };
    it 'should not detect message without NG word' => sub {
        ok(! $filter->detect('hello world!'));
    };
};

