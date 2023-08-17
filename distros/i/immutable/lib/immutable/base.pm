use strict; use warnings;
package immutable::base;
use Scalar::Util 'refaddr';

use overload
    q{""} => sub {
        my ($self) = @_;
        "<${\ ref($self)} ${\ $self->size} ${\ refaddr $self}>";
    },
    q{0+} => sub {
        $_[0]->size;
    },
    q{bool} => sub {
        !! $_[0]->size;
    },
    fallback => 1;

sub id {
    refaddr($_[0]);
}

sub is_empty {
    $_[0]->size == 0;
}

1;
