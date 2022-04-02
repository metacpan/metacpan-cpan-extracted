#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 11;
use Text::Amuse;
use Text::Amuse::Compile;
use Data::Dumper;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $testnum = 141;

my $xelatex = $ENV{TEST_WITH_LATEX};

diag "Creating the compiler";

my $c = Text::Amuse::Compile->new(tex => 1,
                                  pdf => $xelatex,
                                  extra => {
                                            mainfont => 'TeX Gyre Pagella',
                                            papersize => 'a5',
                                           });

{
    my $src = path(qw/t testfile split-volumes.muse/);
    $c->compile("$src");
    my $tex = $src->parent->child('split-volumes.tex');
    ok $tex->exists;
    my $body = $tex->slurp_utf8;
    like $body, qr{tableofcontents}s;
    unlike $body, qr{tableofcontents.*tableofcontents}s, "only one toc found";
    like $body, qr{
                      \{titlepage\}
                      .*
                      \{subtitle\}\{First\sPart
                      .*
                      prova
                      .*
                      aftersubtitle
                      .*
                      \{titlepage\}
                      .*
                      prova
                      .*
                      afterlang
                      .*
                      \{titlepage\}
                      .*
                      prova
                      .*
                      insecondpart
              }xs;
}

{
    my $src = path(qw/t testfile split-volumes-2.muse/);
    $c->compile("$src");
    my $tex = $src->parent->child('split-volumes-2.tex');
    ok $tex->exists;
    my $body = $tex->slurp_utf8;
    like $body, qr{tableofcontents}s;
    unlike $body, qr{tableofcontents.*tableofcontents}s, "only one toc found";
    like $body, qr{printindex}s;
    unlike $body, qr{printindex.*printindex}s, "only one index found";

    like $body, qr{\\index\[names\]\{again\}again.*\\index\[names\]\{again\}again}s,
      "found the index call";

    like $body, qr{
                      \{subtitle\}\{First\sPart
                      .*
                      tableofcontents
                      .*
                      \\addcontentsline\{toc\}\{part\}\{Volume\sPrimo\}
                      .*
                      First
                      .*
                      Second
                      .*
                      \{subtitle\}\{Second\sPart
                      .*
                      \\addcontentsline\{toc\}\{part\}\{Volume\sSecondo\}
                      .*
                      Third
                      .*
                      Fourth
                      .*
                      printindex
              }sx;
}

