package Type::Guess::Role::Unicode;

use Mojo::Base -role;

use Text::VisualPrintf qw/vprintf vsprintf/;
use Text::VisualWidth::PP qw/vwidth/;
use List::Util qw/max/;
use Encode qw/decode encode/;
use utf8;

use overload
    '&{}' => \&to_sub;

sub _length {
    my $class = shift();
    return max map { local $_ = utf8::is_utf8($_) ? $_ : decode("UTF-8", $_); vwidth($_) } @_;
}

sub to_sub {
    my $self = shift;
    my $format = $self->to_string;
    no warnings;
    return sub {
	return encode "UTF-8", vsprintf $format, utf8::is_utf8($_[0]) ? $_ : decode("UTF-8", $_[0]);
    }
}

1
