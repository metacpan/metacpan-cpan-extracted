package Text::ANSI::Highlight::pandoc;

use v5.16;
use warnings;
use Text::ANSI::Highlight ();
use Text::ANSI::Highlight::skylighting ();

# pandoc reads a Markdown text which has the code in fences, and writes
# it for the terminal, with the code in the colors of its language.
# It has skylighting in it, and does not run the command.
our @COMMAND = qw(pandoc -f markdown -t ansi --wrap=none --preserve-tabs);

# The languages are those of skylighting
*language = \&Text::ANSI::Highlight::skylighting::language;

sub markdown { 1 }

# The style: the name of one of pandoc (pygments, haddock, ...), or a
# theme file of KDE.  Set by Text::ANSI::Highlight for a call.  Without
# it, pandoc uses its default, pygments.
#
# The option is --syntax-highlighting in a new pandoc, and
# --highlight-style in an older one, which a new one still takes with a
# warning.  The one which worked is used again.
our $STYLE;
my @STYLE_OPTION = qw(--syntax-highlighting --highlight-style);

sub run {
    my $input = shift;
    defined $STYLE
        or return Text::ANSI::Highlight::run(\@COMMAND, $input);
    for my $option (@STYLE_OPTION) {
        my $out = Text::ANSI::Highlight::run(
            [ @COMMAND, "$option=$STYLE" ], $input) // next;
        @STYLE_OPTION = ($option);
        return $out;
    }
    undef;
}

# The paragraph between the code blocks.  A line of the code never
# looks like this in what pandoc writes: the code is indented.
my $SEPARATOR = 'TextANSIHighlightPandocSeparator';

# All the texts are given to pandoc at once, each in a fence of its
# own.  pandoc reads the fences by its parser of Markdown, so the code
# of one fence has nothing to do with that of the next.
sub highlight {
    my @code = @_;
    my @block = map {
        my($lang, $text) = @$_;
        # a fence longer than any in the text
        my $len = 3;
        $len < length($1) + 1 and $len = length($1) + 1 while $text =~ /(`{3,})/g;
        my $fence = '`' x $len;
        "$fence$lang\n$text" . ($text =~ /\n\z/ ? '' : "\n") . "$fence\n";
    } @code;
    my @none = (undef) x @code;
    my $out = run(join "\n$SEPARATOR\n\n", @block) // return @none;
    # the end of a hyperlink, which pandoc puts at the end
    $out =~ s/\e\]8;;\e\\//g;
    my @out = split /^\Q$SEPARATOR\E\n/m, $out, -1;
    @out == @block or return @none;
    # the code is indented by four columns
    map { Text::ANSI::Highlight::skylighting::clean(s/^ {4}//mgr) } @out;
}

1;
