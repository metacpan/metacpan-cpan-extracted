package QBit::Gettext::Extract::Lang;
$QBit::Gettext::Extract::Lang::VERSION = '0.006';
use qbit;

use base qw(QBit::Class);

__PACKAGE__->abstract_methods(qw(clean));

our %FUNCS = (
    gettext     => [qw(message)],
    ngettext    => [qw(message plural)],
    pgettext    => [qw(context message)],
    npgettext   => [qw(context message plural)],
    d_gettext   => [qw(message)],
    d_ngettext  => [qw(message plural)],
    d_pgettext  => [qw(context message)],
    d_npgettext => [qw(context message plural)],
);

our $RE_eol = qr/\r\n|\n|\r/;

my $RE_q_str  = qr/(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')/;
my $RE_qq_str = qr/(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")/;
my $RE_bq_str = qr/(?:\`)(?:[^\\\`]*(?:\\.[^\\\`]*)*)(?:\`)/;

our $RE_quoted_str = qr/$RE_q_str|$RE_qq_str|$RE_bq_str/;

sub extract_from_file {
    my ($self, $filename, $po) = @_;

    my $text = $self->clean(readfile($filename));

    my $func_re_str = '(?:^|\W)(' . join('|', sort {length($b) <=> length($a)} keys(%FUNCS)) . ')(\W*?\()';

    my $line = 1;

    while ($text =~ /\G(.*?(?:$RE_quoted_str|$func_re_str))/sgc) {
        my ($match, $func, $after_func) = ($1, $2, $3);

        $line += _lines_count($match);

        unless ($func) {
            $line += _lines_count($after_func);
            next;
        }

        my $params_re_str = '\G(\s*' . join('\s*,\s*', map {"($RE_quoted_str)"} 1 .. @{$FUNCS{$func}}) . ')';
        my ($params_match, @params) = $text =~ /$params_re_str/sgc;

        # Dequoting params
        foreach (@params) {
            if (s/^'|'$//sg) {
                s/\\'/'/sg;
            } elsif (s/^"|"$//sg) {
                s/\\"/"/sg;
            }
        }

        if (@params) {
            $po->add_message(
                filename => $filename,
                line     => $line,
                map {$FUNCS{$func}->[$_] => $params[$_]} 0 .. @{$FUNCS{$func}} - 1
            );
        } else {
            print STDERR gettext('Cannot find valid parameters for function "%s" in file "%s" at line %s', $func,
                $filename, $line), "\n";
        }

        $line += _lines_count($after_func) + _lines_count($params_match);
    }
}

sub _lines_count {
    return my $tmp = () = ($_[0] || '') =~ /\r\n|\r|\n/g;
}

TRUE;
