use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Highlighters;

my @highlighter = Highlighters::available();
plan skip_all => 'no highlighter is installed' unless @highlighter;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->rel2abs('lib');
my $cmd = qq{$^X -I"$lib" } . File::Spec->rel2abs('script/ansihighlight');
my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };

sub put {
    my($name, $content) = @_;
    open my $fh, '>:raw', "$dir/$name" or die "$name: $!";
    print $fh $content;
    close $fh;
    "$dir/$name";
}

my $c  = put 'a.c', "int x = 1; /* c */\n";
my $pl = put 'a.pl', "my \$x = 1; # c\n";
my $txt = put 'a.txt', "plain text\n";
my $md = put 'a.md', "# Title\n\n```c\nint x; /* c */\n```\n";

for my $name (@highlighter) {
    my $out = `$cmd -w $name $c`;
    like $out, qr/\e\[/, "$name: a file is colored";
    is $text->($out), "int x = 1; /* c */\n", "$name: the text is the same";

    $out = `$cmd -w $name $c $txt $pl`;
    is $text->($out), "int x = 1; /* c */\nplain text\nmy \$x = 1; # c\n", "$name: files";
    like $out, qr/^plain text$/m, "$name: a file with no language is as it is";

    $out = `$cmd -w $name -l c < $c`;
    like $out, qr/\e\[/, "$name: the standard input with -l";
    is `$cmd -w $name < $c`, "int x = 1; /* c */\n", "$name: without -l, as it is";

    $out = `$cmd --with=$name $md`;
    like $out, qr/\e\[[\d;]+mint\e/, "$name: the code of a Markdown file";
    is $text->($out), "# Title\n\n```c\nint x; /* c */\n```\n", "$name: its text is the same";
}

like `$cmd $c`, qr/\e\[|\Aint x/, 'the default highlighter';
is `$cmd -w gnu $c`, `$cmd -w sourcehighlight $c`, 'gnu is sourcehighlight';
is `$cmd -w sky $c`, `$cmd -w skylighting $c`, 'sky is skylighting';
like `$cmd --list-highlighters`, qr/^pandoc\s+(?:not )?found$/m, '--list-highlighters';
like `$cmd --version`, qr/^ansihighlight \d/, '--version';
like `$cmd --help`, qr/^Usage: ansihighlight/, '--help';
is `$cmd $dir/nosuchfile 2>/dev/null`, '', 'a file which is not there';
isnt $?, 0, 'fails';
`$cmd -w nosuchhighlighter $c 2>/dev/null`;
isnt $?, 0, 'unknown highlighter fails';

done_testing;
