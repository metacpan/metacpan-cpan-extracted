# ============================================================================
package Text::Phonetic::Real;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

our $VERSION = $Text::Phonetic::VERSION;

sub _predicates {
    return 'Text::SomePhoneticAlgorithm';
}

sub _do_encode {
    my ($self,$string) = @_;
    return Text::SomePhoneticAlgorithm::phonetic($string);
}

1;
