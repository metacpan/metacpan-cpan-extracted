use strict;
use warnings;
use utf8;
use Test::More;
use Test::Ika;

{
    package Array;
    sub new { bless [], shift }
    sub push {
        my $self = shift;
        if (1) {
            unshift @{$self}, @_ # <- BUG!
        } else {
            push @$self, @_
        }
    }
    sub at { $_[0]->[$_[1]] }
    sub size { 0+@{+shift}}
    sub map {
        my ($self, $code) = @_;
        map { $code->($_) } @$self;
    }
}

describe 'Array' => sub {
    describe '#push' => sub {
        it 'can push to array' => sub {
            my $a = Array->new();
            $a->push(1);
            is($a->size, 1);
        };
        it 'put pushed element to tail' => sub {
            my $a = Array->new();
            $a->push(1);
            $a->push(2);
            is($a->at(0), 1);
        };
    };
    describe '#map' => sub {
        it 'can apply the function to array' => sub {
            my $a = Array->new();
            $a->push(1);
            $a->push(2);
            is_deeply([$a->map(sub { $_ * 2 })], [2,4]);
        };
    };
};

