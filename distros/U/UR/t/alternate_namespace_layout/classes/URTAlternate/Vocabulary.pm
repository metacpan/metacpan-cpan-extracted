package URTAlternate::Vocabulary;

use strict;
use warnings;

use UR::Object::Type;

use URTAlternate;
class URTAlternate::Vocabulary {
    is => ['UR::Vocabulary'],
    doc => 'A set of words for a given namespace.',
};

my @words_with_special_case = (qw//);

sub _words_with_special_case {
    return @words_with_special_case;
}

1;
