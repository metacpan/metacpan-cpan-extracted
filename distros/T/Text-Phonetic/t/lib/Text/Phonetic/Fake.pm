# ============================================================================
package Text::Phonetic::Fake;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

our $VERSION = $Text::Phonetic::VERSION;

sub _predicates {
    return 'No::Such::Module';
}

sub _do_encode {
    my ($self,$string) = @_;
    return uc($string);
}

1;
