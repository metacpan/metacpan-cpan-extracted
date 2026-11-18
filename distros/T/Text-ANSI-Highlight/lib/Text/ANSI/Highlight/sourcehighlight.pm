package Text::ANSI::Highlight::sourcehighlight;

use v5.16;
use warnings;
use Text::ANSI::Highlight ();

# source-highlight of GNU.  Its style esc is the colors that less
# shows by its lesspipe.  The style and the language are given after
# it (--style-file and -s).
our @COMMAND = qw(source-highlight -f esc);

# The style: the name of a style file of source-highlight without
# .style (esc, esc256, default), or a style file.  Set by
# Text::ANSI::Highlight for a call.
our $STYLE;
our $DEFAULT_STYLE = 'esc';

sub style_option {
    my $style = $STYLE // $DEFAULT_STYLE;
    $style .= '.style' unless $style =~ m{[/.]} or -f $style;
    "--style-file=$style";
}

# The languages, and the extensions of the files, that the command
# knows (source-highlight --lang-list)
my $language;

sub language {
    $language //= do {
        my $list = Text::ANSI::Highlight::run([ $COMMAND[0], '--lang-list' ], '') // '';
        +{ map { /^(\S+) = (\S+)\.lang$/ && $2 ne 'nohilite' ? ($1 => 1) : () } split /\n/, $list };
    };
    $language->{$_[0]} ? $_[0] : undef;
}

# It has no definition of Markdown: the text around the code of a
# Markdown text is left as it is.
sub markdown { 0 }

# The command runs once for each text.
sub highlight {
    map {
        my($lang, $text) = @$_;
        Text::ANSI::Highlight::run([ @COMMAND, style_option(), '-s', $lang ], $text);
    } @_;
}

1;
