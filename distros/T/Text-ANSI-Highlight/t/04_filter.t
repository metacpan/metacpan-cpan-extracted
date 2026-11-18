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

my $text = sub { $_[0] =~ s/\e\[[0-9;]*[mK]//gr };

# Call the filter with a text as the standard input, and return what
# it prints
sub filter {
    my($input, @arg) = @_;
    my $output = '';
    {
        local *STDIN;
        local *STDOUT;
        open STDIN, '<', \$input or die;
        open STDOUT, '>', \$output or die;
        Text::ANSI::Highlight::filter(@arg);
        close STDOUT;
    }
    $output;
}

my $md = "```perl\nmy \$x; # c\n__DATA__\nfoo\n```\n```bash\nf() { echo; } # c\n```\n";

for my $name (@highlighter) {
    my $out = filter($md, '-w', $name);
    is $text->($out), $md, "$name: Markdown by default, the text is the same";
    like $out, qr/^\e\[[\d;]+m(?:my|f\(\))/m, "$name: the code is colored";

    $out = filter("int x; /* c */\n", '-w', $name, '-l', 'c');
    like $out, qr/\e\[[\d;]*[1-9]/, "$name: a language";
    is $text->($out), "int x; /* c */\n", "$name: the text is the same";

    $out = filter("int x; /* c */\n", "--with=$name", '--language=c');
    like $out, qr/\e\[[\d;]*[1-9]/, "$name: long options";

    is filter("plain\n", '-w', $name, '-l', 'nosuchlanguage'), "plain\n",
        "$name: as it is when it is not colored";
    is filter("", '-w', $name), "", "$name: empty";
}

like filter($md), qr/\A```perl\n/, 'the default highlighter';
ok !eval { filter($md, '-w', 'nosuchhighlighter'); 1 }, 'unknown highlighter dies';
ok !eval { filter($md, '--nosuchoption'); 1 }, 'unknown option dies';

# As the function of the tee module of greple, with a highlighter which
# is installed: the default one may not be
SKIP: {
    my $greple = (grep { -x "$_/greple" } File::Spec->path)[0];
    skip 'greple or its tee module is not installed', 4
        unless $greple and eval { require App::Greple::tee; 1 };
    my $dir = tempdir(CLEANUP => 1);
    my $doc = "# Title\n\n```perl\nmy \$x; # c\n__DATA__\nfoo\n```\n\ntext 見出し\n\n"
        . "~~~bash\nf() { echo; } # c\n~~~~\n\n"
        . "   ````c++ title\n   int x; // ``` in it\n   ````\n\n## Last\n";
    open my $fh, '>:utf8', "$dir/a.md" or die;
    print $fh $doc;
    close $fh;
    my $lib = File::Spec->rel2abs('lib');
    my $out = qx{PERL5LIB="$lib:\$PERL5LIB" greple -Mtee '&Text::ANSI::Highlight::filter' -w $highlighter[0] -- --all --cm N -E '^ {0,3}(?<f>(?<c>[`~])\\g{c}{2,}).*\\n(?s:.*?)^ {0,3}\\g{f}\\g{c}*\\h*\$' "$dir/a.md" 2>&1};
    utf8::decode($out);
    is $text->($out), $doc, 'greple -Mtee: the text is the same';
    like $out, qr/^\e\[[\d;]+mmy\e/m, 'greple -Mtee: the first block is colored';
    like $out, qr/^\e\[[\d;]+mf\(\)\e/m, 'greple -Mtee: the block after __DATA__ is colored';
    like $out, qr/^   \e\[[\d;]+mint\e/m, 'greple -Mtee: a longer fence with an indent';
}

done_testing;
