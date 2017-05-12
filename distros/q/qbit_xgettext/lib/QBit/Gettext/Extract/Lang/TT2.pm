package QBit::Gettext::Extract::Lang::TT2;
$QBit::Gettext::Extract::Lang::TT2::VERSION = '0.006';
use qbit;

use base qw(QBit::Gettext::Extract::Lang);

my $RE_quoted_str = $QBit::Gettext::Extract::Lang::RE_quoted_str;

sub clean {
    my ($self, $text) = @_;

    my $new_text = '';
    while ($text =~ /(.*?\[%)(.*?)%]/sg) {
        my ($prev, $code) = ($1, $2);

        $prev =~ s/^.*$//mg;    # Remove template text (outer [% ... %])
        {
            no warnings qw(uninitialized);
            $code =~ s/($RE_quoted_str)|#.*$/$1/mg;    # Remove comments
        }

        $new_text .= $prev . $code;
    }

    return $new_text;
}

TRUE;
