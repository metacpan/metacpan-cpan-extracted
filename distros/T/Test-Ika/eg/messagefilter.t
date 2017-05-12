use strict;
use warnings;
use utf8;
use Test::Ika;
use Test::More;

# see http://d.hatena.ne.jp/t-wada/20100228/p1

package MessageFilter {
    sub new {
        my ($class, $word) = @_;
        bless [$word], $class;
    }
    sub detect {
        my ($self, $msg) = @_;
        index($msg, $self->[0]) >= 0
    }
}

describe 'MessageFilter' => sub {
    context 'with argument "foo"' => sub {
        subject { MessageFilter->new('foo') };

        $it->should_be_detect('hello from foo');
        $it->should_not_be_detect('hello, world!');
    };
};

