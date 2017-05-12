use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Text::Amuse::Functions qw/muse_fast_scan_header/;
use Data::Dumper;

plan tests => 13;

my $testfile = catfile(t => testfiles => 'headers.muse');
my $document = Text::Amuse->new(file => $testfile,
                                debug => 0);

ok($document->as_html);
ok($document->as_latex);
ok($document->header_as_latex);
ok($document->header_as_html);

is($document->as_html, "\n<p>\nHello\n</p>\n");
is($document->as_latex, "\nHello\n\n");

ok($document->document->raw_header);
print Dumper({ $document->document->raw_header });

ok(muse_fast_scan_header($testfile));
print Dumper(muse_fast_scan_header($testfile));

is_deeply(muse_fast_scan_header($testfile),
          { $document->document->raw_header },
          "fast_scan and document->document->raw_header match");

is_deeply($document->header_as_latex,
          {
           title => '\\emph{Title}',
           author => '\\textbf{Prova}',
           DELETED => '',
           date => '<script>hello("a")\'<\\Slash{}script>',
           comment => '[1] [1] [1]',
           subtitle => 'Here we \\textbf{go}',
           bla => '\\emph{hem} \\textbf{ehm} \\textbf{\\emph{bla}}',
          }, "LaTeX header ok");

is_deeply($document->header_as_html,
          {
           title => '<em>Title</em>',
           author =>  '<strong>Prova</strong>',
           DELETED => '',
           date => '&lt;script&gt;hello(&quot;a&quot;)&#x27;&lt;/script&gt;',
           comment => '[1] [1] [1]',
           subtitle => 'Here we <strong>go</strong>',
           bla => '<em>hem</em> <strong>ehm</strong> <strong><em>bla</em></strong>',
          }, "HTML header ok");

is_deeply($document->header_as_latex,
          {
           title => '\\emph{Title}',
           author => '\\textbf{Prova}',
           DELETED => '',
           date => '<script>hello("a")\'<\\Slash{}script>',
           comment => '[1] [1] [1]',
           subtitle => 'Here we \\textbf{go}',
           bla => '\\emph{hem} \\textbf{ehm} \\textbf{\\emph{bla}}',
          }, "LaTeX header ok");

is_deeply($document->header_as_html,
          {
           title => '<em>Title</em>',
           author =>  '<strong>Prova</strong>',
           DELETED => '',
           date => '&lt;script&gt;hello(&quot;a&quot;)&#x27;&lt;/script&gt;',
           comment => '[1] [1] [1]',
           subtitle => 'Here we <strong>go</strong>',
           bla => '<em>hem</em> <strong>ehm</strong> <strong><em>bla</em></strong>',
          }, "HTML header ok");

