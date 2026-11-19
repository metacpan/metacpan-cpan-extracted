package Text::ANSI::Highlight;

our $VERSION = "0.04";

use v5.16;
use warnings;
use Carp;
use File::Temp ();
use File::Spec;
use POSIX ();

# The highlighter which is used when none is given
our $HIGHLIGHTER = 'pandoc';

# Short names of the highlighters
our %SHORT = (
    gnu => 'sourcehighlight',
    sky => 'skylighting',
);

# A file larger than this is left as it is, 0 for no limit.  The
# colored text is many times larger than the file, and takes time to
# show.
our $MAX_SIZE = 256 * 1024;

# Other names of the languages: extensions of files, and the names
# people write after a fence.  The highlighter is asked for the name
# here first, and then for the name as it is.
our %ALIAS = (
    pl => 'perl', pm => 'perl', t => 'perl', psgi => 'perl',
    cpanfile => 'perl',
    sh => 'bash', shell => 'bash', ksh => 'bash', dash => 'bash',
    bashrc => 'bash', profile => 'bash',
    py => 'python', python3 => 'python',
    rb => 'ruby',
    js => 'javascript', mjs => 'javascript', cjs => 'javascript',
    node => 'javascript',
    jsx => 'javascriptreact',
    ts => 'typescript', tsx => 'typescriptreact',
    yml => 'yaml',
    h => 'c',
    'c++' => 'cpp', cc => 'cpp', cxx => 'cpp', hpp => 'cpp', hh => 'cpp',
    'c#' => 'cs', csharp => 'cs',
    'objective-c' => 'objectivec', m => 'objectivec',
    rs => 'rust',
    hs => 'haskell',
    kt => 'kotlin',
    md => 'markdown', mkd => 'markdown',
    mk => 'makefile', make => 'makefile', gnumakefile => 'makefile',
    tex => 'latex',
    htm => 'html',
    el => 'commonlisp', lisp => 'commonlisp',
    ex => 'elixir', exs => 'elixir',
    erl => 'erlang',
    patch => 'diff',
    conf => 'ini', cfg => 'ini',
    tclsh => 'tcl',
);

# The name of a highlighter for a name or a short name, or undef when
# there is no such highlighter.  The module is looked for, and not
# loaded: a highlighter is a module which has the function highlight.
sub highlighter {
    my($class, $name) = @_;
    $name =~ s/:.*//s;
    $name = $SHORT{$name} // $name;
    $name =~ /\A\w+\z/ or return undef;
    my $file = __PACKAGE__ =~ s{::}{/}gr . "/$name.pm";
    for my $dir (grep { !ref } @INC) {
        open my $fh, '<', "$dir/$file" or next;
        local $/;
        return <$fh> =~ /^sub highlight\b/m ? $name : undef;
    }
    undef;
}

# The parameter is "with", the name of the highlighter.  With an odd
# number of arguments, the first is taken for it: new('pandoc') is
# new(with => 'pandoc').
sub new {
    my $class = shift;
    unshift @_, 'with' if @_ % 2;
    my %arg = @_;
    # with => "name:style" is the highlighter and its style; the style
    # parameter wins over it
    my($name, $style) = split /:/, delete $arg{with} // '', 2;
    $style = delete $arg{style} if exists $arg{style};
    undef $style if defined $style and $style eq '';
    # background => 0: the colors of the background are taken out
    my $background = exists $arg{background} ? delete $arg{background} : 1;
    $name = $HIGHLIGHTER if not defined $name or $name eq '';
    $name = $SHORT{$name} // $name;
    croak join(', ', sort keys %arg) . ': unknown parameter' if %arg;
    $name =~ /\A\w+\z/ or croak "$name: invalid highlighter";
    my $module = __PACKAGE__ . "::$name";
    my $file = $module =~ s{::}{/}gr . '.pm';
    unless (eval { require $file; 1 }) {
        croak $@ unless $@ =~ /^Can't locate \Q$file\E /;
        croak "$name: no such highlighter";
    }
    bless { name => $name, module => $module, style => $style,
            background => $background }, $class;
}

sub name  { $_[0]{name} }
sub style { $_[0]{style} }

# The functions of the highlighter.  The style is given in the
# variable $STYLE of its package, for the time of the call: the
# highlighter makes the option of its command from it.
sub _call {
    my($obj, $func) = splice @_, 0, 2;
    no strict 'refs';
    local ${"$obj->{module}::STYLE"} = $obj->{style};
    $obj->{module}->can($func)->(@_);
}

# The name of a language for the highlighter, or undef when it does
# not know it.  Markdown is not a language here: a Markdown text is
# colored by the markdown method.
sub language {
    my($obj, $name) = @_;
    $name = lc($name // '');
    return undef if $name eq '';
    # the name here first: a highlighter can take the same name for
    # another language, as source-highlight takes pl for Prolog
    for ($ALIAS{$name} // (), $name) {
        next if $_ eq 'markdown';
        my $lang = $obj->_call(language => $_);
        return $lang if defined $lang;
    }
    undef;
}

# Color texts.  Takes [ language, text ] of each, and returns as many
# texts, undef for one which is not colored: one with a language which
# the highlighter does not know, an empty one, and one which has an
# escape sequence already.  All are undef when the command of the
# highlighter is not there.
#
# Only the colors are taken from the highlighter: when the text it
# gives is not that of the input, the input is left as it is.
#
# Texts of characters give texts of characters, and those of bytes
# (UTF-8) give bytes.
sub highlight {
    my $obj = shift;
    my @code = @_;
    my $chars = grep { utf8::is_utf8($_->[1]) } @code;
    # All go to the highlighter in one call: the texts, and the pieces
    # of those which are Markdown
    my(@job, @build);
    for my $i (0 .. $#code) {
        my($info, $text) = @{$code[$i]};
        $build[$i] = $obj->_code_plan($info, $text, \@job, $chars);
    }
    $obj->_run(\@job, $chars);
    map { $_->() } @build;
}

# The parts of the text of a block, by the line of its fence: a list
# of [ language, text, label ].  It is one part with the name of the
# fence for the language, when there is no module for a block of that
# name.  The label is what the module calls the part, or undef.
sub parts {
    my($class, $info, $text) = @_;
    my $name = ($info // '') =~ /^\h*(?:\{\h*\.)?([\w+#.-]+)/ ? $1 : '';
    if (my $parts = _block($name)) {
        my @part = $parts->($info, $text);
        return @part if join('', map { $_->[1] } @part) eq $text;
    }
    [ $name, $text ];
}

# Add the jobs for a text to the list, by the line of its fence, the
# name of a language or more, and return a function which gives the
# text in colors when the jobs are done, or undef.
#
# The name is the first word, or the first class in braces as in
# ```{.perl .numberLines}.  Markdown is divided into its pieces.  A
# block which has a module for its name is divided into the parts the
# module tells, each of its language.
sub _code_plan {
    my($obj, $info, $text, $job, $chars) = @_;
    my $name = ($info // '') =~ /^\h*(?:\{\h*\.)?([\w+#.-]+)/ ? $1 : '';
    if (lc($name) =~ /\A(?:markdown|md|mkd)\z/) {
        return $obj->_markdown_plan($text, $job, $chars);
    }
    my @part = parts(undef, $info, $text);
    my @text = map { $_->[1] } @part;
    my @mine;
    for my $i (keys @part) {
        my $lang = $obj->language($part[$i][0]) // next;
        push @$job, { lang => $lang, text => $text[$i], slot => \$text[$i] };
        push @mine, $job->[-1];
    }
    sub { (grep { $_->{ok} } @mine) ? join('', @text) : undef };
}

# Give the texts of the jobs to the highlighter in one call, and put
# what comes back in the slot of each job, when it is the text in
# colors.  A job is { lang, text, slot }, and gets ok when it is done.
sub _run {
    my($obj, $job, $chars) = @_;
    my(@todo, @pair, @crlf);
    for my $j (@$job) {
        my $text = $j->{text};
        my $crlf = _prepare(\$text, $chars) // next;
        push @todo, $j;
        push @pair, [ $j->{lang}, $text ];
        push @crlf, $crlf;
    }
    @pair or return;
    my @out = $obj->_call(highlight => @pair);
    for my $i (0 .. $#todo) {
        my $color = _accept($out[$i], $pair[$i][1], $crlf[$i], $chars) // next;
        $color = _no_background($color) unless $obj->{background};
        ${ $todo[$i]{slot} } = $color;
        $todo[$i]{ok} = 1;
    }
}

# Take the colors of the background out of the SGR sequences of a
# text: 40-47, 100-107, 48 with its color (48;5;N, 48;2;R;G;B, and
# with colons 48:5:N, 48:2::R:G:B), and 49, which puts the default
# one back.
# A sequence which has nothing left is gone.
sub _no_background {
    $_[0] =~ s{\e\[([\d;:]*)m}{
        my @in = split /;/, $1, -1;
        my @out;
        while (@in) {
            my $p = shift @in;
            # the color after 38 and 48: 5;N or 2;R;G;B.  With colons
            # it is in the parameter itself, as 48:2::R:G:B
            my $n = $p =~ /\A[34]8\z/
                ? { 5 => 2, 2 => 4 }->{ $in[0] // '' } // 0 : 0;
            my @color = splice @in, 0, $n;
            next if $p =~ /\A(?:4[0-9]|10[0-7])(?::|\z)/;
            push @out, $p, @color;
        }
        @out || $1 eq '' ? "\e[" . join(';', @out) . 'm' : '';
    }ger;
}

# Make a text ready for the highlighter: bytes, and LF for CR LF.
# Returns undef for a text which is not to be colored, or whether it
# had CR LF.
sub _prepare {
    my($text, $chars) = @_;
    return undef if $$text eq '' or $$text =~ /\e/;
    utf8::encode($$text) if $chars;
    # a highlighter can give LF for CR LF: take CR away, when every
    # line has it
    my $crlf = $$text =~ /\r\n/ ? 1 : 0;
    if ($crlf) {
        return undef if $$text =~ /(?<!\r)\n/;
        $$text =~ s/\r\n/\n/g;
    }
    return undef if $$text =~ /\r/;
    $crlf;
}

# Take what the highlighter gave, when it is the text in colors
sub _accept {
    my($color, $text, $crlf, $chars) = @_;
    defined $color or return undef;
    # the newlines at the ends are those of the input
    $color =~ s/\A\n+//;
    $color =~ s/\n*\z//;
    $color = $1 . $color if $text =~ /\A(\n+)(?=.)/s;
    $color .= $1 if $text =~ /(\n+)\z/;
    # only the colors are taken
    return undef unless $color =~ s/\e\[[\d;:]*m//gr eq $text;
    return undef unless $color =~ /\e\[[\d;:]*[1-9][\d;:]*m/;
    if ($crlf) {
        $color =~ s/((?:\e\[[\d;:]*m)*)\n/$1\r\n/g;
    }
    utf8::decode($color) if $chars;
    $color;
}

# A fenced code block of Markdown: the closing fence is of the same
# character as the opening one, and at least as long (CommonMark).
# $4 is the info string, $5 the code.  A fence which is not closed is
# not a block.
my $FENCE = qr{^( {0,3})((`|~)\3{2,})(.*)\n((?s:.*?))^( {0,3})(\2\3*)(\h*)$}m;

# Color a Markdown text: the code in the fences, each by the language
# of its fence, and the text around them as Markdown, when the
# highlighter knows Markdown.  The lines of the fences are as they
# are.  Returns undef when nothing is colored.
#
# The text around the code is given to the highlighter in pieces
# which have no fence in them.  A definition of Markdown which finds
# the fences by itself can take the rest of the text for the code of
# a fence, as that of skylighting does.  A piece which has a fence,
# one which is not closed, is left as it is.
sub markdown {
    my($obj, $text) = @_;
    my @job;
    my $build = $obj->_markdown_plan($text, \@job, utf8::is_utf8($text));
    $obj->_run(\@job, utf8::is_utf8($text));
    $build->();
}

# The function which gives the parts of a block of that name, when
# there is a module for it: Text::ANSI::Highlight::Block::NAME, with a
# function parts.  It takes the line of the fence after the marks, and
# the text of the block, and returns a list of [ language, text ],
# whose texts are that of the block when they are put together.  The
# language is undef for a part which has none.
my %BLOCK;
sub _block {
    my $name = shift;
    $name =~ /\A\w+\z/ or return undef;
    $BLOCK{$name} //= do {
        my $module = __PACKAGE__ . "::Block::$name";
        (eval "require $module; 1" && $module->can('parts')) || 0;
    };
}

# Divide a Markdown text into pieces, add the jobs for them to the
# list, and return a function which puts the text together again when
# the jobs are done: the text with colors, or undef when nothing of it
# is colored.  Markdown in a fence is divided in the same way, and its
# pieces go to the same list.
sub _markdown_plan {
    my($obj, $text, $job, $chars) = @_;
    # the fences are found in a text of LF; CR comes back at the end,
    # when every line has it
    my $crlf = $text =~ /\r\n/ && $text !~ /(?<!\r)\n/;
    $text =~ s/\r\n/\n/g if $crlf;
    my $markdown = $obj->_call('markdown');
    # the pieces: the text, the opening fence, the code, the closing
    # fence, and so on, to the text at the end
    my(@piece, @mine, @nested);
    my $add = sub {
        my($lang, $slot) = @_;
        push @$job, my $j = { lang => $lang, text => $$slot, slot => $slot };
        push @mine, $j;
    };
    my $prose = sub {
        push @piece, shift;
        return unless $markdown;
        # not a piece which has a fence, or front matter which is not
        # closed at the top
        return if $piece[-1] =~ /^ {0,3}(?:`{3,}|~{3,})/m;
        return if @piece == 1 and $piece[-1] =~ /\A---\h*\n/
            and $piece[-1] !~ /\A.*\n(?s:.*?)^(?:---|\.\.\.)\h*$/m;
        $add->(markdown => \$piece[-1]);
    };
    my $pos = 0;
    while ($text =~ /$FENCE/g) {
        my($start, $end, $from, $to, $info) = ($-[0], $+[0], $-[5], $+[5], $4);
        $prose->(substr $text, $pos, $start - $pos);
        push @piece,
            substr($text, $start, $from - $start),
            substr($text, $from, $to - $from),
            substr($text, $to, $end - $to);
        $pos = $end;
        my $code = \$piece[-2];
        push @nested, [ $code, $obj->_code_plan($info, $$code, $job, $chars) ];
    }
    $prose->(substr $text, $pos);

    sub {
        my $colored = grep { $_->{ok} } @mine;
        for (@nested) {
            my($code, $build) = @$_;
            my $color = $build->() // next;
            $$code = $color;
            $colored++;
        }
        $colored or return undef;
        my $result = join '', @piece;
        $result =~ s/((?:\e\[[\d;:]*m)*)\n/$1\r\n/g if $crlf;
        $result;
    };
}

# The names of interpreters which are not the names of a language
my %INTERPRETER = (
    node  => 'javascript',
    tclsh => 'tcl',
    ksh   => 'bash',
    dash  => 'bash',
);

# The language of a script, by the interpreter on its first line
# (#!/usr/bin/env perl, #!/usr/bin/python3): the name of the command,
# after env and its options and variables, without the version number.
sub interpreter {
    my $line = shift // '';
    $line =~ /\A#!\s*(\S.*)/ or return undef;
    my @word = split ' ', $1;
    my $command = shift @word // return undef;
    if ($command =~ m{(?:\A|/)env\z}) {
        shift @word while @word and $word[0] =~ /\A-|=/;
        $command = shift @word // return undef;
    }
    my $name = $command =~ s{.*/}{}r =~ s/[\d.]+\z//r;
    return undef if $name eq '';
    $INTERPRETER{$name} // $name;
}

sub is_markdown { $_[0] =~ /\.(?:md|markdown|mkd)\z/i }

# The language of a file: by its extension, by its name, and by the
# interpreter on its first line.
sub file_language {
    my($obj, $file, $content) = @_;
    my $base = $file =~ s{.*/}{}r;
    my($ext)  = $base =~ /\.([^.]+)\z/;
    my($line) = $content =~ /\A(.*)/;
    for ($ext // (), $base, interpreter($line) // ()) {
        my $lang = $obj->language($_);
        return $lang if defined $lang;
    }
    undef;
}

# Color the content of a file, by the language its name tells; a
# Markdown file by the markdown method.  The language can be given.
# Returns undef when it is not colored: a file whose language is not
# known, one which has an escape character, an empty one, and one
# larger than $MAX_SIZE.
sub file {
    my($obj, $file, %opt) = @_;
    my $content = _content($file) // return undef;
    $obj->text($content, name => $file, %opt);
}

# Color a text.  The language is given by language, or told from the
# name of a file given by name.
sub text {
    my($obj, $text, %opt) = @_;
    my $lang = $opt{language};
    my $name = $opt{name} // '';
    if (defined $lang ? lc($lang) =~ /\A(?:markdown|md|mkd)\z/ : is_markdown($name)) {
        return $obj->markdown($text);
    }
    $lang //= $obj->file_language($name, $text) // return undef;
    ($obj->highlight([ $lang, $text ]))[0];
}

sub _content {
    my $file = shift;
    return undef unless -f $file;
    my $size = -s _ or return undef;
    return undef if $MAX_SIZE and $size > $MAX_SIZE;
    open my $fh, '<:raw', $file or return undef;
    local $/;
    <$fh>;
}

# Read the standard input and print it in colors, or as it is when it
# is not colored.  The arguments are the options of the highlighter
# (-w, --with) and of the language (-l, --language), which is
# Markdown by default.
#
# This is to be called as a filter: by the tee module of greple, which
# gives the parts of a file to a function and puts back what it prints
# (greple -Mtee '&Text::ANSI::Highlight::filter' -- ...).  The lines
# are those of the input, and only colors are added, so tee can put
# them back by the number of lines; and code blocks of Markdown, given
# with their fences, are colored each by itself.
sub filter {
    require Getopt::Long;
    my %opt = (language => 'markdown');
    Getopt::Long::GetOptionsFromArray(
        [ @_ ], \%opt, 'with|w=s', 'style|s=s', 'language|l=s')
        or croak 'filter: invalid option';
    my $hl = __PACKAGE__->new(
        with => $opt{with} // '',
        defined $opt{style} ? (style => $opt{style}) : ());
    my $text = do { local $/; <STDIN> } // '';
    print $hl->text($text, language => $opt{language}) // $text;
}

# Run a command with the text as its input, and return what it
# writes, or undef when it fails.  Its messages are thrown away.
# For the highlighters.
sub run {
    my($command, $input) = @_;
    my $tmp = File::Temp->new;
    binmode $tmp;
    print $tmp $input;
    $tmp->flush;
    my $pid = open my $fh, '-|';
    defined $pid or return undef;
    if ($pid == 0) {
        # by the file descriptors: STDIN of the caller may not be on 0,
        # as when it is a handle on a string
        open my $in, '<', $tmp->filename or POSIX::_exit(126);
        open my $null, '>', File::Spec->devnull or POSIX::_exit(126);
        POSIX::dup2(fileno $in, 0) // POSIX::_exit(126);
        POSIX::dup2(fileno $null, 2) // POSIX::_exit(126);
        { no warnings 'exec'; exec @$command }
        POSIX::_exit(127);
    }
    binmode $fh;
    my $out = do { local $/; <$fh> };
    close $fh or return undef;
    $out // '';
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Highlight - syntax highlight for the terminal, by a highlighter of your choice

=head1 SYNOPSIS

    use Text::ANSI::Highlight;

    my $hl = Text::ANSI::Highlight->new('pandoc');

    # texts with their languages, all at once
    my($c, $perl) = $hl->highlight([ c => $text1 ], [ perl => $text2 ]);

    # a file, by its name
    print $hl->file('lib/Foo.pm') // $content;

    # a Markdown text: the code in the fences, each by its language
    print $hl->markdown($text) // $text;

    # as a filter of the tee module of greple
    greple -Mtee '&Text::ANSI::Highlight::filter' -- ...

=head1 VERSION

Version 0.04

=head1 DESCRIPTION

This module colors source code for the terminal, with ANSI sequences.
It does not color by itself: it gives the text to a highlighter, a
command which is installed, and takes the colors from it.  The
highlighter can be changed for another, and all of them are used in
the same way.

What comes back is the text which was given, with colors, and nothing
else: when the text a highlighter gives is not that of the input, the
input is left as it is.  A method returns C<undef> for a text which
is not colored, so that the caller shows the text it has:

    print $hl->file($file) // $content;

A text is not colored when the highlighter does not know its language,
when it is empty, when it has an escape character already, and when
the command of the highlighter is not installed or fails.

=head1 HIGHLIGHTERS

=over 4

=item B<pandoc>

L<pandoc|https://pandoc.org/>, by its C<ansi> writer.  It is the
default.  All the texts of a call are given to C<pandoc> in one run,
each in a code block of its own in a Markdown text.  C<pandoc> has
the library of C<skylighting> in it, and the C<skylighting> command
is not used.  The C<ansi> writer came with C<pandoc> 3.4.

=item B<sourcehighlight>, B<gnu>

L<GNU Source-highlight|https://www.gnu.org/software/src-highlite/>,
with its C<esc.style>: the colors that C<less> shows by its
C<lesspipe>.  The command runs once for each text.  It knows fewer
languages, and not Markdown: the text around the code of a Markdown
text is left as it is.

=item B<skylighting>, B<sky>

The C<skylighting> command, the highlighter of C<pandoc> as a program
of its own.  The command runs once for each text.

=back

The colors of C<pandoc> and C<skylighting> are the 16 colors of the
terminal, without background by default.

=head1 STYLES

The colors are those of a style of the highlighter, which tells the
color of the keywords, the comments, the strings and so on.  A style
is given by its name, or by a file.

=over 4

=item B<pandoc>, B<skylighting>

The styles are C<pygments> (default), C<haddock>, C<tango>, C<kate>,
C<espresso>, C<zenburn>, C<breezedark> and C<monochrome>
(C<pandoc --list-highlight-styles>).  C<haddock> has fewer colors.
Some of them have a background color.  A file is a theme of KDE, in JSON, as
C<pandoc --print-highlight-style=haddock> prints.

=item B<sourcehighlight>

A style is a style file of C<source-highlight>, by its name without
C<.style>: C<esc> (default), C<esc256>, C<default> and others, or a
file of your own.

=back

A text is not colored when the highlighter does not have the style.

=head1 HIGHLIGHTER MODULES

A highlighter is a module C<Text::ANSI::Highlight::I<name>> which has
three functions: C<language(I<name>)> returns the name of a language
as the highlighter calls it, or C<undef> when it does not know it;
C<highlight([ I<language>, I<text> ], ...)> returns the texts in
colors, as many as given; and C<markdown()> tells whether the
highlighter knows Markdown.  The style is in the variable C<$STYLE> of
its package while they are called.  The rest is done here.

=head1 BLOCK MODULES

A code block can have parts in more than one language.  A block of
L<pandoc-embedz|https://github.com/tecolicom/pandoc-embedz>
(C<```embedz>, or C<```{.embedz data=file.csv}>) has a configuration
in YAML, a template of Jinja2 and data, with lines of C<---> between
them.

A block of the name I<NAME> is divided into its parts when there is a
module C<Text::ANSI::Highlight::Block::I<NAME>>, and each part is
colored by its language.  The module has one function:
C<parts(I<info>, I<text>)> takes the line of the fence after the
marks and the text of the block, and returns a list of
C<[ I<language>, I<text>, I<label> ]>.  The texts make the text of the
block when they are put together in that order; the block is one part
when they do not.  The language is C<undef> for a part which has none,
like the lines of C<--->.  The label, which can be left out, is the
name of the part (C<config>, C<template> and C<data> in a block of
embedz), for a program which shows the parts in different ways.

L<Text::ANSI::Highlight::Block::embedz> comes with this module.  A
module for a block of your own is found when it is in a directory of
C<@INC>.

=head1 METHODS

=over 4

=item B<new>(I<name>)

=item B<new>(B<with> => I<name>, B<style> => I<style>, B<background> => 0)

Make an object which colors with the highlighter of the name, or of
the short name (C<gnu>, C<sky>).  The
parameter is C<with>, and it can be left out for the first argument:
with an odd number of arguments, the first is the highlighter.
Without it, the highlighter is C<pandoc>
(C<$Text::ANSI::Highlight::HIGHLIGHTER>).  It dies for a name which is
not that of a highlighter.

C<style> is the style of the highlighter, which gives the colors: see
L</STYLES>.  It can be written after the name of the highlighter and
a colon as well, so that the two go in one word, as the value of an
option:

    Text::ANSI::Highlight->new('pandoc', style => 'haddock');
    Text::ANSI::Highlight->new('pandoc:haddock');

C<< background => 0 >> takes the colors of the background, and what
puts the default one back (C<49>), out of what the highlighter gives, for a program which has the background of its
own: a style for a dark screen, as C<breezedark> of pandoc, has one.

=item B<highlighter>(I<name>)

A class method.  Return the name of the highlighter for a name or a
short name (C<sourcehighlight> for C<gnu>), or C<undef> when there is
no such highlighter.  Nothing is loaded.

=item B<highlight>([ I<language>, I<text> ], ...)

Color texts, and return as many: each is the text in colors, or
C<undef> when it is not colored.

The language is a name which the highlighter knows, the extension of
a file (C<pm>, C<yml>), or another name that people use (C<shell>,
C<c++>).  A text of the language C<markdown> is colored as by the
C<markdown> method.

The line of a fence after the marks can be given for the language.
Its first word is the name, or the first class in braces as pandoc
takes it (C<{.perl .numberLines}>), and a block which has a module
(see L</BLOCK MODULES>) is colored by its parts.

Texts of characters give texts of characters, and texts of bytes
(UTF-8) give bytes.  A text with CR LF keeps them.

=item B<markdown>(I<text>)

Color a Markdown text.  The code in a fence (C<```> or C<~~~>) is
colored by the language which is written after the fence, each block
by itself: what is not closed in a block, as a string or a comment,
does not go on to the next.  The text around the code is colored as
Markdown, when the highlighter knows it.  The lines of the fences are
left as they are.  Returns C<undef> when nothing is colored.

=item B<parts>(I<info>, I<text>)

A class method.  Returns the parts of the text of a block as a list
of C<[ I<language>, I<text>, I<label> ]>, by the line of its fence:
those of a block module (see L</BLOCK MODULES>), or one part of the
name of the fence.  No highlighter is called.

=item B<file>(I<file>, B<language> => I<name>)

Color the content of a file.  The language is told from the extension
of the file, from its name (C<Makefile>), or from the interpreter on
its first line (C<#!/usr/bin/env perl>), unless it is given.  A
Markdown file (C<.md>, C<.markdown>) is colored by the C<markdown>
method.  A file larger than C<$Text::ANSI::Highlight::MAX_SIZE> bytes
(256 KB by default, 0 for no limit) is not colored.

=item B<text>(I<text>, B<name> => I<file>, B<language> => I<name>)

The same for a text.  The language is given, or told from the name of
a file and the first line of the text.

=item B<language>(I<name>)

The name of a language as the highlighter calls it, or C<undef> when
it does not know the language.

=back

=head1 FUNCTIONS

=over 4

=item B<filter>(I<options>)

Read the standard input and print it in colors, or as it is when it
is not colored.  The options are C<-w I<name>> (C<--with>), the
highlighter, C<-s I<style>> (C<--style>), and C<-l I<language>>
(C<--language>), which is C<markdown> by default.

It is a function for the C<tee> module of B<greple>, which gives parts
of a file to a function and puts back what it prints.  Next command
colors the code blocks of a Markdown file:

    greple -Mtee '&Text::ANSI::Highlight::filter' -- --all --cm N -E \
      '^ {0,3}(?<f>(?<c>[`~])\g{c}{2,}).*\n(?s:.*?)^ {0,3}\g{f}\g{c}*\h*$' \
      file.md

The pattern is a fenced code block: a fence of three or more C<`> or
C<~>, and the closing one of the same character, at least as long.
The blocks are given together, with their fences, and each is colored
by itself.  The lines are those of the input, so C<tee> puts them back
by their number.

=back

=head1 MARKDOWN AND SKYLIGHTING

The C<skylighting> command colors a Markdown file by a definition of
Markdown which finds the fences by itself, and it can take the rest
of the file for the code of a fence: after a function of a shell
script, or C<__DATA__> of Perl, in a code block (skylighting 0.15).
This module finds the fences by itself, and gives the highlighter
the code of each block, and the text around them in pieces which have
no fence.

=head1 SEE ALSO

L<ansihighlight>, the command.

L<Text::ANSI::Highlight::IO> makes a program which reads files by
C<E<lt>E<gt>> read them in colors, as it is.

L<App::Greple::tee>

L<SyntaxHighlight::Any> is a common interface to highlighters as well.

L<Syntax::Kamelon> and L<Syntax::Highlight::Engine::Kate> color by the
syntax definitions of Kate in Perl, and L<Syntax::SourceHighlight> by
the library of GNU Source-highlight, without running a command.
L<Text::VimColor> colors by Vim.

L<https://pandoc.org/>, L<https://www.gnu.org/software/src-highlite/>,
L<https://github.com/jgm/skylighting>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
