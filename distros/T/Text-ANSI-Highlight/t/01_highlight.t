use v5.16;
use warnings;
use utf8;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Highlighters;

use Text::ANSI::Highlight;

my @highlighter = Highlighters::available();
plan skip_all => 'no highlighter is installed' unless @highlighter;

my $dir = tempdir(CLEANUP => 1);
my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };

sub put {
    my($name, $content) = @_;
    open my $fh, '>:raw', "$dir/$name" or die "$name: $!";
    print $fh $content;
    close $fh;
    "$dir/$name";
}

# The same holds for every highlighter
for my $name (@highlighter) {
    my $hl = Text::ANSI::Highlight->new($name);
    is $hl->name, $name, "$name: name";

    subtest "$name: texts" => sub {
        my @in = ([ c => "int x = 1; /* c */\n" ],
                  [ perl => "my \$x = 1; # perl\nmy \$y;\n" ],
                  [ bash => "echo \"\$HOME\" # sh\n" ]);
        my @out = $hl->highlight(@in);
        is scalar(@out), 3, 'as many as given';
        for my $i (keys @in) {
            like $out[$i], qr/\e\[[\d;]*[1-9]/, "$in[$i][0]: colored";
            is $text->($out[$i]), $in[$i][1], "$in[$i][0]: the text is the same";
            unlike $out[$i], qr/\e\]|\e\[[\d;]*[^\d;m]/, "$in[$i][0]: colors only";
        }
    };

    subtest "$name: a text ends where it ends" => sub {
        my @in = ([ perl => "my \$x;\n__DATA__\nfoo\n" ],
                  [ bash => "f() { echo; }\n[[ \$a == b ]] && f\n" ],
                  [ c    => "/* open\n" ],
                  [ c    => "int after = 1; /* c */\n" ]);
        my @out = $hl->highlight(@in);
        is $text->($out[$_] // ''), $in[$_][1], "text $_ is the same" for keys @in;
        like $out[3], qr/\e\[[\d;]*[1-9][\d;]*mint\e/, 'the text after them has the colors of its own';
    };

    subtest "$name: lines" => sub {
        my $c = "\nint x; /* c */\n\n\n\tint y;  /* tab */\n\n\n";
        my($out) = $hl->highlight([ c => $c ]);
        is $text->($out), $c, 'empty lines at the top, inside and at the end, and a tab';
        is((split /^/, $out)[2], "\n", 'an empty line has no sequence');

        my($no_nl) = $hl->highlight([ c => "int x; /* c */" ]);
        is $text->($no_nl), "int x; /* c */", 'without the newline at the end';

        my $fence = "x = '```' # c\ny = '````'\n    z = 1\n";
        my($f) = $hl->highlight([ python => $fence ]);
        is $text->($f), $fence, 'fences and indents in the text';

        my($crlf) = $hl->highlight([ c => "int x; /* c */\r\nint y;\r\n" ]);
        like $crlf, qr/\e\[[\d;]*[1-9]/, 'CRLF: colored';
        is $text->($crlf), "int x; /* c */\r\nint y;\r\n", 'CRLF: the text is the same';
        is scalar(() = $crlf =~ /\r\n/g), 2, 'CRLF: CR and LF stay together';

        my($wide) = $hl->highlight([ perl => "my \$x = 'あ'; # い\n" ]);
        is $text->($wide), "my \$x = 'あ'; # い\n", 'wide characters';
        ok utf8::is_utf8($wide), 'characters in, characters out';
        my $bytes = "my \$x = '\xe3\x81\x82'; # c\n";
        my($b) = $hl->highlight([ perl => $bytes ]);
        is $text->($b), $bytes, 'bytes in, bytes out';
        ok !utf8::is_utf8($b), 'bytes';
    };

    subtest "$name: not colored" => sub {
        my @out = $hl->highlight(
            [ nosuchlanguage => "foo\n" ],
            [ ''             => "foo\n" ],
            [ c              => "" ],
            [ c              => "\e[31mred\e[m\n" ],
            [ c              => "int x; /* c */\n" ],
        );
        is scalar(@out), 5, 'as many as given';
        is $out[0], undef, 'a language which is not known';
        is $out[1], undef, 'no language';
        is $out[2], undef, 'an empty text';
        is $out[3], undef, 'a text with an escape sequence';
        like $out[4], qr/\e\[[\d;]*[1-9]/, 'the others are colored';
        is_deeply [ $hl->highlight() ], [], 'none';
    };

    subtest "$name: language" => sub {
        ok defined $hl->language($_), $_ for qw(perl Perl pm pl sh py js c h);
        # the other names here win over those of the highlighter:
        # source-highlight takes pl for Prolog
        is $hl->language('pl'), $hl->language('perl'), 'pl is Perl';
        is $hl->language('pm'), $hl->language('perl'), 'pm is Perl';
        is $hl->language('sh'), $hl->language('bash'), 'sh is bash';
        is $hl->language('nosuchlanguage'), undef, 'not known';
        is $hl->language(''), undef, 'empty';
        is $hl->language(undef), undef, 'undef';
        is $hl->language('markdown'), undef, 'markdown is not a language here';
        is $hl->language('md'), undef;
    };

    subtest "$name: when the command fails" => sub {
        no strict 'refs';
        my $command = "Text::ANSI::Highlight::${name}::COMMAND";
        my @in = ([ c => "int x;\n" ], [ perl => "my \$x;\n" ]);
        local @$command = ('nosuchcommand-text-ansi-highlight');
        is_deeply [ $hl->highlight(@in) ], [ undef, undef ], 'no command';
        local @$command = ($^X, '-e', 'print "garbage\n"; 1', '--');
        is_deeply [ $hl->highlight(@in) ], [ undef, undef ], 'a command which gives something else';
        local @$command = ($^X, '-e', 'local $/; $_ = <STDIN>; s/int/\e[31mlong\e[0m/g; s/my/\e[31mour\e[0m/g; print; 1', '--');
        is_deeply [ $hl->highlight(@in) ], [ undef, undef ], 'a command which changes the text';
    };

    subtest "$name: file" => sub {
        for (
            [ 'a.c',      "int x = 1; /* c */\n\nint y;\n" ],
            [ 'a.pm',     "package A;\nmy \$x = 1; # c\n" ],
            [ 'Makefile', "all: # c\n\techo done\n" ],
            [ 'noext',    "#!/bin/bash\necho hello # c\n" ],
            [ 'env',      "#!/usr/bin/env perl\nmy \$x = 1; # c\n" ],
        ) {
            my($file, $content) = @$_;
            my $out = $hl->file(put $file, $content);
            like $out, qr/\e\[[\d;]*[1-9]/, "$file: colored";
            is $text->($out // ''), $content, "$file: the text is the same";
        }
        is $hl->file(put 'plain', "some text\nwith no interpreter\n"), undef, 'no language';
        is $hl->file(put 'unknown', "#!/usr/local/bin/nosuchlanguage\ntext\n"), undef,
            'unknown interpreter';
        is $hl->file(put 'e.c', "\e[31mred\e[m\n"), undef, 'a file with ESC';
        is $hl->file(put 'empty.c', ""), undef, 'an empty file';
        is $hl->file("$dir/nosuchfile.c"), undef, 'no file';
        my $big = put 'big.c', "int x; /* c */\n" x 100;
        local $Text::ANSI::Highlight::MAX_SIZE = 1499;
        is $hl->file($big), undef, 'over the limit';
        local $Text::ANSI::Highlight::MAX_SIZE = 1500;
        like $hl->file($big), qr/\e\[/, 'within the limit';
        like $hl->file(put('x.txt', "int x; /* c */\n"), language => 'c'), qr/\e\[/,
            'the language can be given';
    };
}

subtest 'new' => sub {
    ok !eval { Text::ANSI::Highlight->new('nosuchhighlighter'); 1 },
        'unknown highlighter dies';
    like $@, qr/nosuchhighlighter: no such highlighter/, 'with the name';
    ok !eval { Text::ANSI::Highlight->new('a b'); 1 }, 'invalid name dies';
    ok !eval { Text::ANSI::Highlight->new(with => 'nosuchhighlighter'); 1 }, 'the same by with';
    ok !eval { Text::ANSI::Highlight->new(nosuchparameter => 1); 1 }, 'unknown parameter dies';
    like $@, qr/nosuchparameter: unknown parameter/, 'with the name';

    # an odd number of arguments: the first is the highlighter, as if
    # "with" was before it
    my $default = $Text::ANSI::Highlight::HIGHLIGHTER;
    is(Text::ANSI::Highlight->new->name, $default, 'the default');
    is(Text::ANSI::Highlight->new('sourcehighlight')->name, 'sourcehighlight', 'by the first argument');
    is(Text::ANSI::Highlight->new(with => 'sourcehighlight')->name, 'sourcehighlight', 'by with');

    # the name of a highlighter, without loading it
    is(Text::ANSI::Highlight->highlighter('pandoc'), 'pandoc', 'highlighter: a name');
    is(Text::ANSI::Highlight->highlighter('gnu'), 'sourcehighlight', 'highlighter: a short name');
    is(Text::ANSI::Highlight->highlighter('sky'), 'skylighting', 'highlighter: another');
    is(Text::ANSI::Highlight->highlighter('nosuchhighlighter'), undef, 'highlighter: not one');
    is(Text::ANSI::Highlight->highlighter('IO'), undef, 'highlighter: a module which is not one');
    is(Text::ANSI::Highlight->highlighter('a b'), undef, 'highlighter: not a word');
    is(Text::ANSI::Highlight->highlighter(''), undef, 'highlighter: empty');

    # short names
    is(Text::ANSI::Highlight->new('gnu')->name, 'sourcehighlight', 'gnu is sourcehighlight');
    is(Text::ANSI::Highlight->new('sky')->name, 'skylighting', 'sky is skylighting');
    is(Text::ANSI::Highlight->new(with => 'gnu')->name, 'sourcehighlight', 'by with');
};

subtest 'interpreter' => sub {
    my $interp = \&Text::ANSI::Highlight::interpreter;
    is $interp->("#!/bin/sh\n"), 'sh';
    is $interp->("#!/usr/bin/env perl\n"), 'perl';
    is $interp->("#!/usr/bin/env -S perl -w\n"), 'perl';
    is $interp->("#!/usr/bin/env FOO=1 python3\n"), 'python';
    is $interp->("#! /usr/local/bin/perl5.36 -w\n"), 'perl';
    is $interp->("#!/usr/bin/env node\n"), 'javascript';
    is $interp->("#!/usr/bin/tclsh8.6\n"), 'tcl';
    is $interp->("#!/bin/ksh\n"), 'bash';
    is $interp->("# not an interpreter line\n"), undef;
    is $interp->("#!\n"), undef;
    is $interp->(""), undef;
    is $interp->(undef), undef;
};

done_testing;
