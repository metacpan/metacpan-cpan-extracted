package Text::Xatena::Util;

use strict;
use warnings;

our @EXPORT = qw(escape_html template unindent);
use Exporter::Lite;
use Text::MicroTemplate;

my %escape = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&#34;',
    "'" => '&#39;',
);
sub escape_html ($) { ## no critic
    my ($str) = @_;
    my $escape = join "|", keys %escape;
    $str =~ s{($escape)}{ $escape{$1} }ego;
    $str;
}

sub unindent ($) { ## no critic
    my $string = shift;
    my ($indent) = ($string =~ /^\n?(\s*)/);
    $string =~ s/^$indent//gm;
    $string =~ s/\s+$//;
    $string;
}

sub template ($$) { ## no critic
    my ($template, $keys) = @_;

    my $mt = Text::MicroTemplate->new(
        tag_start   => '{{',
        tag_end     => '}}',
        template    => unindent $template,
        escape_func => undef,
    );

    my $code     = $mt->code;
    my $expand   = join('; ', map { "my \$$_ = \$_[0]->{$_}" } @$keys);
    my $renderer = eval << "    ..." or die $@; ## no critic
        sub {
            $expand;
            $code->();
        }
    ...
}

1;
__END__



