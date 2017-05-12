#!perl

use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use Test::More tests => 141;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $muse = <<'MUSE';
#title The title ()
#author The author ()
#notes just a test notes field

<br>

#begin

First chunk àà (0)

* First part (1)

#one
First part body ćđ (1)

** First chapter (2)

#two
First chapter body (2)

*** First section (3)

First section body (3)

**** First subsection (4)

#four
First subsection (4)

 Item :: Blabla (4)

* Second part (5)

#five
Second part body (5)

** Second chapter (6)

#six
Second chapter body (6)

*** Second section (7)

Second section body (7)

**** Second subsection (8)

Second subsection (8)

 Item :: Blabla

*** Third section (9)

[[#begin]] [[#one]] [[#six]] [[#five]]

Third section (9)

 Item :: Blabla

*** Fourth section (10)

[[#six]] [[#five]] [[#begin]] [[#one]] 

Blabla (10)

MUSE

my $dh = File::Temp->newdir(CLEANUP => !$ENV{NO_CLEANUP});
my $wd = $dh->dirname;
diag "Working in $wd";
my @files = (qw/first second third/);

# populate
my $c = Text::Amuse::Compile->new(tex => 1, html => 1, epub => 1,
                                  pdf => !!$ENV{TEST_WITH_LATEX});

my $missing = qr/\([245678]\)/;
my $expected = qr/\(0\).*\(1\).*\(3\).*\(9\)/s;

for my $file (@files) {
    my $filename = catfile($wd, $file. '.muse');
    my $body = $muse;
    $body =~ s/\(/- $file - (/g;
    like $body, $missing;
    write_file($filename, $body);
    ok($c->compile($filename), "Plain $filename is ok");
    ok($c->compile($filename . ':0,1,3,9,100,pre,post'));
    foreach my $ext ('.tex', '.html') {
        my $ext_body = read_file(catfile($wd, $file . $ext));
        like $ext_body, $expected, "Chunks found";
        unlike $ext_body, $missing, "Missing chunks not found";
    }
    my $epub_body = _get_epub_xhtml(catfile($wd, $file . '.epub'));
    like $epub_body, $expected, "EPUB looks fine";
    unlike $epub_body, $missing, "Missing chunks not found in epub";
  SKIP: {
        skip "Not testing pdf", 1 unless $ENV{TEST_WITH_LATEX};
        ok(-f catfile($wd, $file . '.pdf'));
    }
}

my $check_body = qr/Hello\ World
                    .*
                    The\ title\ -\ first
                    .*
                    First\ part\ body\ ćđ\ -\ first\ -\ \(1\)
                    .*
                    First\ section\ body\ -\ first\ -\ \(3\)
                    .*
                    First\ chunk\ àà\ -\ second\ -\  \(0\)
                    .*
                    First\ section\ body\ -\ second\ -\ \(3\)
                    .*
                    Third\ section\ -\ second\ -\ \(9\)
                    .*
                    Third\ section\ -\ third\ -\ \(9\)
                   /xsi;

{
    ok($c->compile({
                    path => $wd,
                    name => 'new-test',
                    files => \@files,
                    title => 'Hello World',
                   }), "plain virtual compiled ok");
    ok($c->compile({
                    path => $wd,
                    name => 'new-test',
                    files => [
                              $files[0] . ':pre,1,3,post',
                              $files[1] . ':pre,0,3,9,post',
                              $files[2] . ':pre,9,100,post',
                             ],
                    title => 'Hello World',
                   }), "new-test compiled");
    my $epub_body = _get_epub_xhtml(catfile($wd, 'new-test.epub'));
    $epub_body =~ s/\n\n+/\n/gs;
    like $epub_body, $check_body, "epub looks fine";
    unlike $epub_body, $missing, "epub has not the excluded parts";
    foreach my $string ('piece000004.xhtml#text-amuse-label-piece000002-begin',
                        '"#text-amuse-label-piece000002-one"', # the missing one
                       ) {
        like $epub_body, qr{\Q$string\E}, "Found $string in EPUB";
    }

    foreach my $ext ('.tex') {
        # html has no support for merged, yet
        my $ext_body = read_file(catfile($wd, 'new-test' . $ext));
        like $ext_body, $check_body, "body for $ext is ok";
        unlike $ext_body, $missing, "body for $ext has no excluded pieces";
        foreach my $string ('\hyperdef{piece000001amuse}{one}{}%',
                            '\hyperdef{piece000002amuse}{begin}{}%',
                            '\hyperref{}{piece000002amuse}{begin}{begin}',
                            '\hyperref{}{piece000002amuse}{one}{one}',
                            '\hyperref{}{piece000003amuse}{begin}{begin}',
                            '\hyperref{}{piece000003amuse}{one}{one}') {
            like $ext_body, qr{\Q$string\E}, "Found altered refs and defs";
        }
    }
  SKIP: {
        skip "Not testing pdf", 1 unless $ENV{TEST_WITH_LATEX};
        ok(-f catfile($wd, 'new-test.pdf'));
    }
}

# check preamble and postamble

# $c = Text::Amuse::Compile->new(epub => 1, tex => 1);

foreach my $spec ({
                   pre => 1,
                   1 => 1,
                   post => 1,
                  },
                  {
                   pre => 1,
                   1 => 1,
                  },
                  {
                   post => 1,
                   1 => 1,
                  },
                  {
                   1 => 1,
                  }) {
    my $specstring = join(',', keys %$spec);
    my $name = 'muse-' .  $specstring . '-merged';
    $name =~ s/,/-/g;
    ok($c->compile({
                    path => $wd,
                    name => $name,
                    title => $name,
                    files => [ $files[0] . ':' . $specstring ],
                   }));
    ok($c->compile(catfile($wd, $files[0] . '.muse:' . $specstring)));
    my $index = 0;
    my $match_pre = qr{The\ title\ -\ first\ -\ \(\)}sx;
    my $match_pre_tex = qr{\\huge\s*$match_pre}s;
    my $match_pre_epub = qr{<h1[^>]*?>\s*$match_pre\s*</h1>}s;
    my $match_post = qr{just a test notes field};
    foreach my $finalname ($files[0], $name) {
        $index++;
        my $epub = catfile($wd, $finalname . '.epub');
        my $tex = catfile($wd, $finalname . '.tex');
      SKIP: {
            skip "pdf $finalname not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f catfile($wd, "$finalname.pdf"), "pdf $finalname created");
        }
        ok (-f $tex, "$tex created");
        ok (-f $epub, "$epub created");
        my $tex_body = read_file($tex);
        my $epub_body = _get_epub_xhtml($epub);
        for my $body ($tex_body, $epub_body) {
            like $body, qr/First part body ćđ - first/, "body matches";
            unlike $body, $missing;
        }
        if ($spec->{pre}) {
            like $tex_body, $match_pre_tex, "tex body for $finalname has pre";
            like $epub_body, $match_pre_epub, "epub body for $finalname has pre";
        }
        else {
            unlike $tex_body, $match_pre_tex, "tex body for $finalname has no pre";
            unlike $epub_body, $match_pre_epub, "epub body for $finalname has no pre";
        }
        if ($spec->{post}) {
            like $tex_body, $match_post, "tex body for $finalname has post";
            like $epub_body, $match_post, "epub body for $finalname has post";
        }
        else {
            unlike $tex_body, $match_post, "tex body for $finalname has no post";
            unlike $epub_body, $match_post, "epub body for $finalname has no post";
        }
    }
}

# same as compile-merged
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
        push @html, "<!-- $piece -->\n",
          read_file(File::Spec->catfile($tmpdir->dirname, $piece));
    }
    return join('', @html);
}
