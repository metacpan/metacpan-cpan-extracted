use v5.16;
use warnings;
use utf8;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Highlighters;

my @highlighter = Highlighters::available();
plan skip_all => 'no highlighter is installed' unless @highlighter;

# an IO::Factotum which takes an object
sub T::With::file { undef }
eval {
    require IO::Factotum;
    IO::Factotum::register(with => bless {}, 'T::With');
    IO::Factotum::clear();
    1;
} or plan skip_all => 'IO::Factotum which takes an object is not installed';

my $dir = tempdir(CLEANUP => 1);
my $inc = join ' ', map { qq{-I"$_"} } File::Spec->rel2abs('lib'), grep { !ref } @INC;
my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };

sub put {
    my($name, $content) = @_;
    open my $fh, '>:utf8', "$dir/$name" or die "$name: $!";
    print $fh $content;
    close $fh;
    "$dir/$name";
}

my $c   = put 'a.c',   "int x = 1; /* c */\nint y;\n";
my $pl  = put 'b.pl',  "my \$x = 'あ'; # perl\n";
my $txt = put 'c.txt', "plain text\n";

sub perl {
    my $out = qx{$^X $inc @_ 2>&1};
    utf8::decode($out);
    $out;
}

# A program which reads by <> works as it is
for my $name (@highlighter) {
    my $M = "-MText::ANSI::Highlight::IO=$name";

    my $out = perl($M, q{-ne 'print "$ARGV:$.:$_"; close ARGV if eof'}, $c, $txt, $pl);
    my @line = split /^/, $out;
    is scalar(@line), 4, "$name: the lines of the files";
    like $line[0], qr/^\Q$c\E:1:.*\e\[[\d;]*[1-9]/, "$name: a line in colors, with \$ARGV and \$.";
    like $line[1], qr/^\Q$c\E:2:/, "$name: the second line";
    is $line[2], "$txt:1:plain text\n", "$name: a file with no language is as it is";
    like $line[3], qr/^\Q$pl\E:1:.*\e\[/, "$name: the next file";
    is $text->($out), "$c:1:int x = 1; /* c */\n$c:2:int y;\n$txt:1:plain text\n$pl:1:my \$x = 'あ'; # perl\n",
        "$name: the text is the same";

    is perl($M, '-pe 1', "< $c"), "int x = 1; /* c */\nint y;\n",
        "$name: the standard input is as it is";

    like perl("-MText::ANSI::Highlight::IO=with,$name", '-pe 1', $c), qr/\e\[/,
        "$name: with => name";

    # in a script
    my $script = put "$name.pl", "use Text::ANSI::Highlight::IO with => '$name';\nprint while <>;\n";
    like perl($script, $c), qr/\e\[/, "$name: use in a script";

    # a script which is not changed
    my $plain = put 'cat.pl', "print while <>;\n";
    like perl($M, $plain, $c), qr/\e\[/, "$name: a script as it is, with -M";
    is perl($plain, $c), "int x = 1; /* c */\nint y;\n", "$name: and without";

    # setup gives the highlighter to IO::Factotum, and does not touch <>
    my $setup = put 'setup.pl', <<"END";
use Text::ANSI::Highlight::IO ();
use IO::Factotum;
Text::ANSI::Highlight::IO->setup('$name');
print tied(*ARGV) ? "tied\\n" : "not tied\\n";
print IO::Factotum::open_input(shift)->getlines;
END
    $out = perl($setup, $c);
    like $out, qr/\Anot tied\n/, "$name: setup does not tie ARGV";
    like $out, qr/\e\[/, "$name: setup: open_input gives the colors";
}

like perl('-MText::ANSI::Highlight::IO', '-pe 1', $c), qr/\e\[|\Aint x/, 'the default highlighter';
like perl('-MText::ANSI::Highlight::IO=nosuchhighlighter', '-e 1'),
    qr/nosuchhighlighter: no such highlighter/, 'unknown highlighter dies';

done_testing;
