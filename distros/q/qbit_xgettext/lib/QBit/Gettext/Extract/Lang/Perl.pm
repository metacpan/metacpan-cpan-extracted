package QBit::Gettext::Extract::Lang::Perl;
$QBit::Gettext::Extract::Lang::Perl::VERSION = '0.006';
use qbit;

use base qw(QBit::Gettext::Extract::Lang);

my $RE_eol        = $QBit::Gettext::Extract::Lang::RE_eol;
my $RE_quoted_str = $QBit::Gettext::Extract::Lang::RE_quoted_str;

sub clean {
    my ($self, $text) = @_;

    {
        no warnings qw(uninitialized);
        $text =~ s/($RE_quoted_str)|#.*$/$1/mg;    # Remove comments
    };

    # Remove PODs
    while ($text =~ /^(.*?(?:^|$RE_eol))(=\w.+?(?:$RE_eol=cut|$))(.*)$/sg) {
        my ($prev_text, $pod_text, $post_text) = ($1, $2, $3);
        $pod_text =~ s/^.*$//mg;
        $text = $prev_text . $pod_text . $post_text;
    }

    return $text;
}

TRUE;
