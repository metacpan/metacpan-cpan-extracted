package Text::ANSI::Highlight::skylighting;

use v5.16;
use warnings;
use Text::ANSI::Highlight ();

# skylighting, the highlighter of pandoc, as a command, with the 16
# colors of the terminal.  The style and the language are given after
# it (-S or -t, and -s).
our @COMMAND = qw(skylighting -f ansi -r -C 16);

# The style: the name of one of skylighting (pygments, haddock, ...),
# or a theme file of KDE.  Set by Text::ANSI::Highlight for a call.
our $STYLE;
our $DEFAULT_STYLE = 'pygments';

# A style is a file when it has a slash or a dot, or is one
sub style_is_file { $_[0] =~ m{[/.]} or -f $_[0] }

sub style_option {
    my $style = $STYLE // $DEFAULT_STYLE;
    style_is_file($style) ? ('-t', $style) : ('-S', $style);
}

# The languages of skylighting 0.15 (pandoc --list-highlight-languages,
# pandoc 3.14).  A language is given to the command only when it is
# here: the command takes time to look for one it does not know.
my %LANGUAGE = map { $_ => 1 } qw(
    abc abnf actionscript ada agda apache asciidoc asn1 asp ats awk bash
    bibtex boo c cabal changelog clojure cmake cobol coffee coldfusion
    comments commonlisp context cpp crystal cs css csv curry d dart
    debiancontrol default desktop diff djangotemplate dockerfile dosbat
    dot doxygen doxygenlua dtd eiffel elixir elixireex elixirheex elm
    email erlang fasm fortranfixed fortranfree fsharp gap gcc gdscript
    gleam glsl gnuassembler go gpr graphql groovy haml hamlet haskell
    haxe html idl idris ini isocpp j java javadoc javascript
    javascriptreact jinja jira json jsp julia k kotlin latex lex
    lilypond literatecurry literatehaskell llvm logfile lua m4 makefile
    mandoc mathematica matlab maxima mediawiki mermaid meson metafont
    mips modelines modula2 modula3 monobasic mustache nasm nginx nim
    ninja nix noweb objectivec objectivecpp ocaml ocamllex ocamlyacc
    octave odin opencl orgmode pascal perl php pike postscript povray
    powershell prolog protobuf pure purebasic purescript python q qml
    quarto r racket raku rdoc relaxng relaxngcompact rest rhtml
    rmarkdown roff rtf ruby rust sas sass scala scheme sci scss sed sgml
    sml sparql spdxcomments sql sqlmysql sqlpostgresql stan stata swift
    systemverilog tcl tcsh terraform texinfo textile tlaplus todo toml
    typescript typst verilog vhdl vue xml xorg xslt xul yacc yaml zig
    zsh
);

sub language { $LANGUAGE{$_[0]} ? $_[0] : undef }

# The text around the code of a Markdown text is colored
sub markdown { 1 }

# The sequences of skylighting which do nothing: \e[22;23;24m after
# every reset, and a reset where there is no color to reset, at the
# top of a line or after another reset, with text between them or not.
# skylighting resets after every word, colored or not.
sub clean {
    local $_ = shift;
    s/\e\[0m\K\e\[22;23;24m//g;
    1 while s/(?:^|\e\[0m)[^\e\n]*\K\e\[0m//mg;
    $_;
}

# The command runs once for each text.
sub highlight {
    map {
        my($lang, $text) = @$_;
        my $out = Text::ANSI::Highlight::run(
            [ @COMMAND, style_option(), '-s', $lang ], $text);
        defined $out ? clean($out) : undef;
    } @_;
}

1;
