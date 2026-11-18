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
my $code = "if (x == 1) { return \"a\"; } /* c */\n";

# A style of each highlighter other than its default one, and what
# tells it in the output
my %other = (
    pandoc          => 'haddock',
    skylighting     => 'haddock',
    sourcehighlight => 'esc256',
);

# The default style of each
my %default = (
    pandoc          => 'pygments',
    skylighting     => 'pygments',
    sourcehighlight => 'esc',
);

subtest 'new' => sub {
    my $hl = Text::ANSI::Highlight->new('sourcehighlight');
    is $hl->style, undef, 'no style';
    $hl = Text::ANSI::Highlight->new('sourcehighlight:esc256');
    is $hl->name, 'sourcehighlight', 'name:style, the name';
    is $hl->style, 'esc256', 'name:style, the style';
    $hl = Text::ANSI::Highlight->new('gnu:esc256');
    is $hl->name, 'sourcehighlight', 'a short name with a style';
    is $hl->style, 'esc256';
    $hl = Text::ANSI::Highlight->new(with => 'gnu', style => 'esc256');
    is $hl->style, 'esc256', 'the style parameter';
    $hl = Text::ANSI::Highlight->new('gnu:default', style => 'esc256');
    is $hl->style, 'esc256', 'the parameter wins over the one in the name';
    $hl = Text::ANSI::Highlight->new(':esc256');
    is $hl->name, $Text::ANSI::Highlight::HIGHLIGHTER, 'a style alone: the default highlighter';
    is $hl->style, 'esc256';
    $hl = Text::ANSI::Highlight->new('gnu:');
    is $hl->style, undef, 'an empty style is none';
    $hl = Text::ANSI::Highlight->new('gnu:/path/to/my.style');
    is $hl->style, '/path/to/my.style', 'the style can be a path';

    is(Text::ANSI::Highlight->highlighter('gnu:esc256'), 'sourcehighlight',
       'highlighter: a name with a style');
    is(Text::ANSI::Highlight->highlighter('nosuch:esc256'), undef, 'highlighter: not one');
};

for my $name (@highlighter) {
    my $default = Text::ANSI::Highlight->new($name);
    my($plain) = $default->highlight([ c => $code ]);

    subtest "$name: a style by its name" => sub {
        my $hl = Text::ANSI::Highlight->new("$name:$other{$name}");
        my($out) = $hl->highlight([ c => $code ]);
        like $out, qr/\e\[[\d;]*[1-9]/, 'colored';
        is $text->($out), $code, 'the text is the same';
        isnt $out, $plain, 'not as by the default style';

        my($same) = Text::ANSI::Highlight->new($name, style => $other{$name})
            ->highlight([ c => $code ]);
        is $same, $out, 'the same by the style parameter';

        my($named) = Text::ANSI::Highlight->new("$name:$default{$name}")
            ->highlight([ c => $code ]);
        is $named, $plain, "the default style is $default{$name}";

        # the style is that of the object: the next one has its own
        my($again) = $default->highlight([ c => $code ]);
        is $again, $plain, 'another object is not changed';
    };

    subtest "$name: a style which is not there" => sub {
        my $hl = Text::ANSI::Highlight->new("$name:nosuchstyle");
        is_deeply [ $hl->highlight([ c => $code ]) ], [ undef ], 'not colored';
        is $hl->file(__FILE__), undef, 'a file';
    };

    subtest "$name: Markdown and files" => sub {
        my $hl = Text::ANSI::Highlight->new("$name:$other{$name}");
        my $md = "# T\n\n```c\n$code```\n";
        my $out = $hl->markdown($md);
        is $text->($out), $md, 'Markdown: the text is the same';
        my($styled) = $hl->highlight([ c => $code ]);
        like $out, qr/\Q$styled\E/, 'Markdown: the code is in the style';
    };
}

# A style in a file
SKIP: {
    skip 'source-highlight is not installed', 2
        unless grep { $_ eq 'sourcehighlight' } @highlighter;
    my $file = "$dir/my.style";
    open my $fh, '>', $file or die;
    print $fh "keyword green b ;\ncomment red ;\n";
    close $fh;
    my($out) = Text::ANSI::Highlight->new("gnu:$file")->highlight([ c => $code ]);
    like $out, qr/\e\[01;32mif\e/, 'sourcehighlight: a style file, the keyword';
    like $out, qr/\e\[31m\/\* c \*\/\e/, 'sourcehighlight: the comment';
}

SKIP: {
    my($sky) = grep { /pandoc|skylighting/ } @highlighter;
    skip 'neither pandoc nor skylighting is installed', 4 unless $sky;
    my $pandoc = (grep { -x "$_/pandoc" } File::Spec->path)[0];
    skip 'pandoc is not installed, to print a theme', 4 unless $pandoc;
    my $file = "$dir/my.theme";
    system(qq{pandoc --print-highlight-style=haddock > "$file" 2>/dev/null}) == 0
        or skip 'pandoc can not print a theme', 4;
    for my $name (grep { /pandoc|skylighting/ } @highlighter) {
        my($by_name) = Text::ANSI::Highlight->new("$name:haddock")->highlight([ c => $code ]);
        my($by_file) = Text::ANSI::Highlight->new($name, style => $file)->highlight([ c => $code ]);
        like $by_file, qr/\e\[[\d;]*[1-9]/, "$name: a theme file, colored";
        is $by_file, $by_name, "$name: as the style it was printed from";
    }
}

# The command and the filter
{
    my $lib = File::Spec->rel2abs('lib');
    my $cmd = qq{$^X -I"$lib" } . File::Spec->rel2abs('script/ansihighlight');
    my $c = "$dir/a.c";
    open my $fh, '>', $c or die;
    print $fh $code;
    close $fh;
    my $name = $highlighter[0];
    my($want) = Text::ANSI::Highlight->new("$name:$other{$name}")->highlight([ c => $code ]);
    is `$cmd -w $name:$other{$name} $c`, $want, 'ansihighlight -w name:style';
    is `$cmd -w $name --style=$other{$name} $c`, $want, 'ansihighlight --style';
    is `$cmd -w $name -s $other{$name} $c`, $want, 'ansihighlight -s';
}

done_testing;
