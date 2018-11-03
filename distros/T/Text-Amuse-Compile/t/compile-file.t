#!perl
use strict;
use warnings;
use utf8;
use Test::More;

use File::Spec;
use Data::Dumper;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use Text::Amuse::Compile::Devel qw/create_font_object/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;


my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $targetdir = File::Spec->catfile('t', 'testfile');
chdir $targetdir or die $!;

my $testnum = 133;

# check if there is xelatex installed
my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    plan tests => $testnum;
    diag "Testing with XeLaTeX";
}
else {
    diag "No TEST_WITH_LATEX environment variable found, avoiding use of xelatex";
    plan tests => ($testnum - 1);
}


my $tt = Text::Amuse::Compile::Templates->new;
my $file = Text::Amuse::Compile::File->new(name => 'test',
                                           fonts => create_font_object(),
                                           suffix => '.muse',
                                           templates => $tt);


is($file->name, 'test');
is($file->suffix, '.muse');
ok($file->templates->html);
ok(!$file->is_deleted);
is($file->status_file, 'test.status');
like $file->document->as_latex, qr/\\& Ćao! \\emph\{another\}/;
like $file->document->as_html, qr{<em>test</em> &amp; Ćao! <em>another</em>};
ok($file->tt);

foreach my $ext (qw/.html .tex .pdf .bare.html .epub .zip .status/) {
    unlink $file->name . $ext;
}

ok ((! -f 'test.html'));
diag "Compile the html";
$file->html;
ok ((-f 'test.html'), "html found");

my $html_body = read_file ('test.html');
like $html_body, qr{<em>test</em> &amp; Ćao! <em>another</em>};
# print $html_body;

ok ((! -f 'test.tex'), "tex not found");
$file->tex;
ok ((-f 'test.tex'), "tex found");

ok (! -f 'test.pdf');
if ($xelatex) {
    $file->pdf;
    ok((-f 'test.pdf'), "pdf found");
}

ok (! -f 'test.bare.html');
$file->bare_html;
ok ((-f 'test.bare.html'), 'bare html found');


ok (! -f 'test.epub');
$file->epub;
ok(( -f 'test.epub'), "epub found");


ok (! -f 'test.zip');
$file->zip;
ok(( -f 'test.zip'), "zip found");

$file->purge_all;

foreach my $ext ($file->purged_extensions) {
    ok((! -f "test$ext"), "test$ext purged");
}


$file = Text::Amuse::Compile::File->new(name => 'deleted',
                                        fonts => create_font_object(),
                                        suffix => '.muse',
                                        templates => $tt);


foreach my $ext ($file->purged_extensions) {
    write_file($file->name . $ext, '1');
    ok(( -f "deleted$ext"), "deleted$ext now exists (manually)");
}



diag "Calling check_status";
$file->purge_all if $file->is_deleted;
foreach my $ext ($file->purged_extensions) {
    ok(! -f "deleted$ext", "deleted$ext purged by mark_as_open");
}
ok(! -f 'deleted.html');

$file->cleanup;

my $c = Text::Amuse::Compile->new;

$c->compile('deleted.muse');

ok(-f "deleted.status", "Found the deleted.status file");
my $line = read_file('deleted.status');
like $line, qr/^DELETED/, "status file marked as deleted";


foreach my $ext ($file->purged_extensions) {
    ok(! -f "deleted$ext", "deleted$ext doesn't exist");
}
ok(! -f 'deleted.html');
