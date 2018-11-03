#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 43;

use File::Spec;
use Data::Dumper;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

use Text::Amuse::Compile::Merged;
use Text::Amuse::Compile::Devel qw/explode_epub
                                  create_font_object/;
chdir File::Spec->catdir(qw/t merged-dir/) or die $!;

my $doc = Text::Amuse::Compile::Merged->new(files => [qw/first.muse second.muse/],
                                            title => "Title is Bla *bla* bla",
                                            author => "Various",
                                           );

ok($doc);

ok($doc->docs == 2);

is $doc->language, 'french', "Main language is french";
is $doc->language_code, 'fr', "Code ok";
is_deeply $doc->other_languages, [ qw/english/ ];
is_deeply $doc->other_language_codes, [ qw/en/ ];

foreach my $d ($doc->docs) {
    ok($d->isa('Text::Amuse'));
}

is_deeply([ $doc->files ], [qw/first.muse second.muse/]);

is_deeply({ $doc->headers }, {
                          title => "Title is Bla *bla* bla",
                          author => "Various",
                         });

my $tex = $doc->as_latex;

like $tex, qr/First \\emph\{file\} text/, "Found the first file body";
like $tex, qr/Second file \\emph\{text\}/, "Found the second file body";
like $tex, qr/Pallino Pinco/, "Found the first author";
like $tex, qr/First file subtitle/, "Found the first text subtitle";
like $tex, qr/Pallone Ponchi/, "Found the second file author";
like $tex, qr/usekomafont\{subtitle\}\{Second file subtitle\\par\}/, "Found the title of the second file";

is_deeply $doc->header_as_latex,
  {
   title => "Title is Bla \\emph{bla} bla",
   author => "Various",
  }, "Header as latex OK";

is_deeply $doc->header_as_html,
  {
   title => "Title is Bla <em>bla</em> bla",
   author => "Various",
  }, "Header as latex OK";


ok $doc->header_defined->{author}, "Found author in the header";
ok $doc->header_defined->{title}, "Found title in the header";
ok !$doc->header_defined->{subtitles}, "Subtitle not found";

my @html_frags = $doc->as_splat_html;
ok (scalar(@html_frags), "Found splat HTML fragments");
my $html = join("\n", @html_frags);

like $html, qr{First <em>file</em> text}, "Found the first file body";
like $html, qr{Second file <em>text</em>}, "Found the second file body";
like $html, qr{Pallino Pinco}, "Found the first author";
like $html, qr{First file subtitle}, "Found the first text subtitle";
like $html, qr{<h2.*?>Pallone Ponchi</h2>}, "Found the second file author";
like $html, qr{<h2.*?>Second file subtitle</h2>}, "Found the title of the second file";

ok $doc->raw_html_toc, "Found the toc";

is_deeply([$doc->raw_html_toc],
          [
           {
             'index' => 0,
             'level' => 1,
             'string' => 'First file'
           },
           {
             'index' => 1,
             'level' => 2,
             'string' => 'First file'
           },
           {
             'index' => 2,
             'level' => '2',
             'string' => 'Another chap'
           },
           {
             'index' => 3,
             'string' => 'Chap',
             'level' => '2'
           },
           {
             'level' => 1,
             'index' => 4,
             'string' => 'Second file'
           },
           {
             'string' => 'Second file',
             'index' => 5,
             'level' => 2
           },
           {
             'index' => 6,
             'string' => 'Another chap',
             'level' => '2'
           },
           {
             'index' => 7,
             'level' => '2',
             'string' => 'Chap'
           }
          ],
          "Toc looks ok") or diag Dumper([$doc->raw_html_toc]);

is (scalar($doc->raw_html_toc), scalar(@html_frags), "Number of entries match");

my @attachments = $doc->attachments;
ok (scalar(@attachments), "Found attachments " . join(" ", @attachments));

is_deeply(\@attachments, ['logo-1.png', 'logo.png']);

use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;

my $templates = Text::Amuse::Compile::Templates->new;

my $compile = Text::Amuse::Compile::File->new(
                                              document => $doc,
                                              name => 'test',
                                              suffix => '.muse',
                                              virtual => 1,
                                              templates => $templates,
                                              fonts => create_font_object(),
                                             );

my $outtex = read_file($compile->tex);

like $outtex, qr/First \\emph\{file\} text/, "Found the first file body";
like $outtex, qr/Second file \\emph\{text\}/, "Found the second file body";
like $outtex, qr/Pallino Pinco/, "Found the first author";
like $outtex, qr/First file subtitle/, "Found the first text subtitle";
like $outtex, qr/Pallone Ponchi/, "Found the second file author";
like $outtex, qr/usekomafont\{subtitle\}\{Second file subtitle\\par\}/, "Found the title of the second file";

like $outtex, qr/\\title\{Title is Bla \\emph\{bla\} bla\}/, "Doc title found";

# my $outpdf = $compile->pdf;
$compile->purge_all;

my $epub = $compile->epub;
ok ($epub, "EPUB produced");
ok (-f $epub, "$epub exists");
my $epub_html = explode_epub($epub);
# diag $epub_html;
like ($epub_html, qr{author.*Pallino\sPinco.*
                     title.*First\sfile.*
                     subtitle.*First\sfile\ssubtitle.*
                     notes.*This\sis\sthe\sfirst\sfile.*
                     First\s<em>file</em>\stext.*
                     author.*Pallone\sPonchi.*
                     title.*Second\sfile.*
                     subtitle.*Second\sfile\ssubtitle.*
                     notes.*This\sis\sthe\ssecond\sfile.*
                     Second\sfile\s<em>text</em>}xs,
      "HTML looks ok");

$compile->purge_all;

