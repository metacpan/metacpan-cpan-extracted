use strict;
use warnings;

use Test::More;
use Text::Amuse;
use Text::Amuse::Compile;
use File::Spec;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $testnum = 143;

my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    plan tests => $testnum;
    diag "Testing with XeLaTeX";
}
else {
    diag "No TEST_WITH_LATEX environment variable found, avoiding use of xelatex";
    plan tests => ($testnum - 1);
}

diag "Creating the compiler";

my $c = Text::Amuse::Compile->new(tex => 1,
                                  pdf => $xelatex,
                                  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=861938 in stretch
                                  extra => {
                                            mainfont => 'TeX Gyre Pagella',
                                            papersize => 'a5',
                                           });

diag "Try to compile";

$c->compile({
             path  => File::Spec->catdir(qw/t merged-dir/),
             files => [qw/first forth second third nosections/],
             name  => 'my-new-test',
             title => 'My new shiny test',
             subtitle => 'Another one',
             date => 'Today!',
             source => 'Text::Amuse::Compile',
            });

diag "Compiler finished, starting tests";

my $base = File::Spec->catfile(qw/t merged-dir my-new-test/);
ok(-f "$base.tex", "$base.tex created");

my $outtex = read_file("$base.tex");

like $outtex, qr/First \\emph\{file\} text/, "Found the first file body";
like $outtex, qr/Second file \\emph\{text\}/, "Found the second file body";
like $outtex, qr/Pallino Pinco/, "Found the first author";
like $outtex, qr/First file subtitle/, "Found the first text subtitle";
like $outtex, qr/Pallone Ponchi/, "Found the second file author";
like $outtex, qr/usekomafont\{subtitle\}\{Second file subtitle\\par}/, "Found the title of the second file";

like $outtex, qr/\\title\{My new shiny test}/, "Doc title found";


like $outtex, qr/\\selectlanguage\{russian\}/, "Found language selection";
like $outtex, qr/\\selectlanguage\{english\}/, "Found language selection";
like $outtex, qr/\\setmainlanguage\{french\}/, "Found language selection";
like $outtex, qr/\\setotherlanguages\{.*russian.*\}/, "Found russian lang";
like $outtex, qr/\\setotherlanguages\{.*english.*\}/, "Found english lang";
like $outtex, qr/\\russianfont/, "Found russian font";
like $outtex, qr/No sections/;
like $outtex, qr/pippo no section/;
like $outtex, qr/Here the body goes/;

foreach my $pnum (1..4) {
    like $outtex, qr{hyperref\{\}\{piece00000\Q$pnum\Eamuse\}},
      "Found hyperref with $pnum piece";
    like $outtex, qr{hyperdef\{piece00000\Q$pnum\Eamuse\}},
      "Found hyperdef with $pnum piece";
}


if ($xelatex) {
    ok(-f "$base.pdf", "$base.pdf created");
}

my @chunks = grep { /language/ } split(/\n/, $outtex);

like shift(@chunks), qr/setmainlanguage\{french\}/, "Found french";
like shift(@chunks), qr/setotherlanguages\{(english,macedonian,russian)\}/,
  "Found other languages";


foreach my $l (qw/russian english macedonian/) {
    like shift(@chunks), qr/\\selectlanguage\{\Q$l\E\}/, "Found $l";
}

$c = Text::Amuse::Compile->new(epub => 1);

ok(! -f "$base.epub", "target dir clean");

my @texts = (qw/first second third forth
                forth third second first/);

$c->compile({
             path  => File::Spec->catdir(qw/t merged-dir/),
             files => [ @texts ],
             name  => 'my-new-test',
             title => 'My *new* shiny test',
             subtitle => 'Another *one*',
             date => '*Today*!',
             source => 'Text::Amuse::Compile',
            });

ok(-f "$base.epub", "$base.epub created");

my $epub_html = _get_epub_xhtml($base . '.epub');
my $htmlindex = 0;
foreach my $text (@texts) {
    my $file = File::Spec->catfile(qw/t merged-dir/, $text . '.muse');
    my $museobj = Text::Amuse->new(file => $file);
    foreach my $piece ($museobj->as_splat_html) {
        my $current = index($epub_html, $piece, $htmlindex);
        ok($current > $htmlindex, "$current is greater than $htmlindex")
          or diag "$piece was not found in the output $epub_html";
        # diag substr($epub_html, $htmlindex, $current - $htmlindex);
        $htmlindex = $current + length($piece);
    }
    # here we check the toc, if the pieces are there and are in the
    # correct order. First we check the sorting of the playOrder, then
    # the pieces.

}

{
    my $toc = substr($epub_html, 0, index($epub_html, '</ncx'));
    # diag $toc;
    my $current_toc = 0;
    while ($toc =~ m/playOrder="(\d+)"/g) {
        my $playorder = $1;
        is ($playorder, $current_toc + 1, "Order ok: $playorder");
        $current_toc = $playorder;
    }
    $current_toc = -1;
    while ($toc =~ m/src="piece0*(\d+).xhtml/g) {
        my $playorder = $1;
        is ($playorder, $current_toc + 1, "Order of pieces ok: $playorder");
        $current_toc = $playorder;
    }

}
like $epub_html, qr{My <em>new</em> shiny test}, "Found the title";
like $epub_html, qr{Another <em>one</em>}, "Found the author";
like $epub_html, qr{<em>Today</em>!}, "Found the date";

unless ($ENV{NO_CLEANUP}) {
    foreach my $ext (qw/aux log pdf tex toc status epub/) {
        my $remove = "$base.$ext";
        if (-f $remove) {
            unlink $remove or warn $!;
        }
    }
}

sub _get_epub_xhtml {
    my $epub = shift;
    my $zip = Archive::Zip->new;
    die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
    my $tmpdir = File::Temp->newdir(CLEANUP => 1);
    $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
      or die "Couldn't extract $epub OPS into $tmpdir";
    opendir (my $dh, $tmpdir->dirname) or die $!;
    my @pieces = sort grep { /\Apiece\d+\.xhtml\z/ } readdir($dh);
    closedir $dh;
    my @html;
    foreach my $piece ('toc.ncx', 'titlepage.xhtml', @pieces) {
        my $html_piece = read_file(File::Spec->catfile($tmpdir->dirname, $piece));
        # neutralize internal linking for testing purposes
        $html_piece =~ s/(href=")piece[0-9]+\.xhtml(#.*?")/$1$2/g;
        $html_piece =~ s/(text-amuse-label-)piece[0-9]+-/$1/g;
        push @html, "<!-- $piece -->\n", $html_piece;
    }
    return join('', @html);
}
