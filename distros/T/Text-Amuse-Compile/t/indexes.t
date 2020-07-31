#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 16;
use Text::Amuse::Compile;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Indexer;
use Text::Amuse::Compile::Devel qw/create_font_object/;
use Data::Dumper;
use Path::Tiny;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $workingdir = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
my $c = Text::Amuse::Compile->new(
                                  tex => 1,
                                  pdf => $ENV{TEST_WITH_LATEX},
                                  logger => sub {
                                      diag @_;
                                  },
                                 );

{
    my $file = path(qw/t testfile index-me/);
    my $cfile = Text::Amuse::Compile::File->new(
                                                name => "$file",
                                                suffix => '.muse',
                                                templates => Text::Amuse::Compile::Templates->new,
                                                logger => sub {
                                                    diag @_;
                                                },
                                                fonts => create_font_object(),
                                               );
    ok $cfile;
    my $doc = $cfile->document;
    diag Dumper($cfile->document_indexes);
    my $indexer = Text::Amuse::Compile::Indexer->new(latex_body => $doc->as_latex,
                                                     logger => sub { diag @_ },
                                                     index_specs => [ $cfile->document_indexes ]);
    diag Dumper($indexer->specifications);
    foreach my $spec (@{ $indexer->specifications }) {
        diag Dumper($spec->matches);
    }
    my $found  = scalar(grep { /\\index/ } split(/\n/, $indexer->interpolate_indexes));
    ok $found, "Found $found indexes";
    foreach my $spec (@{ $indexer->specifications }) {
        ok $spec->total_found, "Found " . $spec->index_label . ':' . $spec->total_found;
    }
}

{
    my $src = path(qw/t testfile index-me-1.muse/);
    diag "Using " . $workingdir->dirname;
    my $file = $workingdir->child('indexes.muse');
    my $src_body = $src->slurp_utf8;
    $file->spew_utf8($src_body);
    $c->compile("$file");
    my $tex = $workingdir->child('indexes.tex');
    my $pdf = $workingdir->child('indexes.pdf');
  SKIP:
    {
        skip "pdf test not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok $pdf->exists, "$pdf exists";
    }
    ok $tex->exists, "$tex exists";
    my $tex_body = $tex->slurp_utf8;

    like $tex_body, qr/\\begin\{comment\}\s+INDEX testć: Kazalo imena/,
      "non index comment is in place";
    like $tex_body, qr/\\makeindex\[name=imena,title=\{\\textbackslash\{\}crash\\\{Žćđ\\\}\}\]/;
    like $tex_body, qr/\\makeindex\[name=mjesta,title=\{Kazalo mjesta\}\]/;

    my $tex_indexed;

    if ($tex_body =~ m/STARTHERE(.*)ENDHERE/s) {
        $tex_indexed = $1;
    }

    eq_or_diff([ split(/\r?\n/, $tex_indexed) ],
               [ split(/\r?\n/, path(qw/t testfile index-me-1.expected/)->slurp_utf8) ]);

    # now we create a same file, but without the magic comment, so
    # indexes are not triggered
    my $file_n = $workingdir->child('no-indexes.muse');
    $src_body =~ s/<comment>.*?<\/comment>//gs;
    $file_n->spew_utf8($src_body);
    $c->compile("$file_n");
    my $tex_n = $workingdir->child('no-indexes.tex');
    my $pdf_n = $workingdir->child('no-indexes.pdf');
  SKIP:
    {
        skip "pdf test not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok $pdf_n->exists, "$pdf_n exists";
    }
    ok $tex_n->exists, "$tex exists";
    my $tex_no_indexed;
    if ($tex_n->slurp_utf8 =~ m/STARTHERE(.*)ENDHERE/s) {
        $tex_no_indexed = $1;
    }
    # remove the indexes from $tex_indexed and see if it's ok
    isnt $tex_indexed, $tex_no_indexed, "Differences ok";

    $tex_indexed =~ s/\\index\[\w+\]\{.*?\}//g;

    eq_or_diff([split /\n/, $tex_indexed],
               [split /\n/, $tex_no_indexed]);

}

{
    my $src = path(qw/t testfile index-me-2.muse/);
    my $file = $workingdir->child('short.muse');
    $file->spew_utf8($src->slurp_utf8);
    $c->compile("$file");
    my $tex = $workingdir->child('short.tex');
    my $pattern = "\\index[imena]{Try}\\emph{em}  \\index[imena]{Prova}Prova~prova  \\index[imena]{Try}\\emph{em}";
    like $tex->slurp_utf8, qr/\Q$pattern\E/;
}


foreach my $f (qw/index-me-3/) {
    my $src = path(qw/t testfile/, "$f.muse");
    my $file = $workingdir->child("$f.muse");
    $file->spew_utf8($src->slurp_utf8);
    $c->compile("$file");
    my $tex = $workingdir->child("$f.tex");
    my $tex_body;
    if ($tex->slurp_utf8 =~ m/STARTHERE(.*)ENDHERE/s) {
        $tex_body = $1;
    }
    else {
        die "Failure reading $f.tex";
    }
    eq_or_diff([ split(/\r?\n/, $tex_body) ],
               [ split(/\r?\n/, path(qw/t testfile/, "$f.expected")->slurp_utf8) ]);
}
