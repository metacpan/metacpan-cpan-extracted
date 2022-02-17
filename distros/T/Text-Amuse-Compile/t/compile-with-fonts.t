#!perl

use strict;
use warnings;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Temp;
use File::Spec;
use Path::Tiny;
use JSON::MaybeXS;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Test::More tests => 299;
use Data::Dumper;

my $wd = File::Temp->newdir;

my $inopt_re =  qr{[^]]*?};

my $pathre = qr{$inopt_re Path= \Q$wd\E $inopt_re}xs;

my $font_re = qr{(?:\{(serif|sans|mono)-regular\.otf\}\[
                 $pathre
                 BoldFont=(serif|sans|mono)-bold\.otf $inopt_re
                 BoldItalicFont=(serif|sans|mono)-bolditalic\.otf $inopt_re
                 ItalicFont=(serif|sans|mono)-italic\.otf $inopt_re
                 \]
                 |
                 \[
                 $pathre
                 BoldFont=(serif|sans|mono)-bold\.otf $inopt_re
                 BoldItalicFont=(serif|sans|mono)-bolditalic\.otf $inopt_re
                 ItalicFont=(serif|sans|mono)-italic\.otf $inopt_re
                 \]
                 \{(serif|sans|mono)-regular\.otf\}
                 )
            }sx;

unless ($wd =~ m/\A([A-Za-z0-9\.\/_-]+)\z/) {
    $font_re = qr{\[$inopt_re\]\{DejaVu(?:Serif|Sans|SansMono)\}};
}

my $font_size_in_pt = qr{font-size:.*pt};

foreach my $base (qw/regular italic bold bolditalic/) {
    foreach my $family (qw/mono sans serif/) {
        path(qw/t fonts/, $base  . '.otf')->copy(path($wd, "$family-$base.otf"));
    }
}

my @fonts = (
             {
              name => 'DejaVuSerif',
              type => 'serif',
              map { $_ => File::Spec->catfile($wd, 'serif-' . $_ . '.otf') } (qw/regular italic
                                                                                 bold bolditalic/)
             },
             {
              name => 'DejaVuSans',
              type => 'sans',
              map { $_ => File::Spec->catfile($wd, 'sans-' . $_ . '.otf') } (qw/regular italic
                                                                                 bold bolditalic/)
             },
             {
              name => 'DejaVuSansMono',
              type => 'mono',
              map { $_ => File::Spec->catfile($wd, 'mono-' . $_ . '.otf') } (qw/regular italic
                                                                                bold bolditalic/)
             },
            );

my $file = File::Spec->catfile($wd, 'fontspec.json');
my $json = JSON::MaybeXS->new(pretty => 1, canonical => 1, utf8 => 0)->encode(\@fonts);
write_file($file, $json);
my $muse_file = File::Spec->catfile($wd, 'test.muse');
write_file($muse_file, "#title Test fonts\n\nbla bla bla\n\n");
my $tex = $muse_file;
$tex =~ s/\.muse/.tex/;
my $pdf = $muse_file;
$pdf =~ s/\.muse/.pdf/;
my $epub = $muse_file;
$epub =~ s/\.muse/.epub/;
my $html = $muse_file;
$html =~ s/\.muse/.html/;

my $xelatex = $ENV{TEST_WITH_LATEX};
foreach my $fs ($file, \@fonts) {
    my $c = Text::Amuse::Compile->new(epub => 1,
                                      html => 1,
                                      tex => 1,
                                      fontspec => $fs,
                                      extra => {
                                                mainfont => 'DejaVuSerif',
                                                sansfont => 'DejaVuSans',
                                                monofont => 'DejaVuSansMono',
                                               },
                                      pdf => $xelatex);
    ok $c->fonts, "Font accessor built";
    foreach my $family (qw/mono sans main/) {
        ok $c->fonts->$family->has_files, "$family has files" or die;
    }
    $c->compile($muse_file);
    {
        ok (-f $tex, "$tex produced");
        my $texbody = read_file($tex);
        like $texbody, qr/(mainfont|babelfont\{rm\})$font_re/;
        like $texbody, qr/(monofont|babelfont\{tt\})$font_re/;
        like $texbody, qr/(sansfont|babelfont\{sf\})$font_re/ or die Dumper($c);
    }
  SKIP: {
        skip "No pdf required", 1 unless $xelatex;
        ok (-f $pdf);
    }
    {
        ok (-f $epub);
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        my $zip = Archive::Zip->new;
        die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
        $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
          or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
        my $css = read_file(File::Spec->catfile($tmpdir->dirname, "stylesheet.css"));
        my $html_body = read_file($html);
        foreach my $tcss ($css, $html_body) {
            like $tcss, qr/font-family: "DejaVuSerif"/, "Found font-family" or die;
            unlike $tcss, $font_size_in_pt;
        }
        my $manifest = read_file(File::Spec->catfile($tmpdir, "content.opf"));
        diag $manifest;
        foreach my $family (qw/serif sans mono/) {
            foreach my $file (qw/regular.otf bold.otf italic.otf bolditalic.otf/) {
                my $epubfile = File::Spec->catfile($tmpdir, "$family-$file");
                ok (-f $epubfile, "$epubfile embedded");
                like $css, qr/src: url\("\Q$family-$file\E"\) format\(.+\)/, "Found the css rules for $file" or die;
                like $manifest, qr/href="\Q$family-$file\E"/, "Found the font in the manifest" or die;
            }
        }
        like $manifest, qr{(application/x-font.*){12}}s;
    }
}

# disable EPUB font embedding
foreach my $fs ($file, \@fonts) {
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => $fs,
                                      extra => {
                                                mainfont => 'DejaVuSerif',
                                                sansfont => 'DejaVuSans',
                                                monofont => 'DejaVuSansMono',
                                               },
                                      epub_embed_fonts => 0,
                                      pdf => $xelatex);
    ok $c->fonts, "Font accessor built";
    $c->compile($muse_file);
    {
        ok (-f $tex, "$tex produced");
        my $texbody = read_file($tex);
        like $texbody, qr/(mainfont|babelfont\{rm\})$font_re/;
        like $texbody, qr/(monofont|babelfont\{tt\})$font_re/;
        like $texbody, qr/(sansfont|babelfont\{sf\})$font_re/ or die Dumper($c);
    }
  SKIP: {
        skip "No pdf required", 1 unless $xelatex;
        ok (-f $pdf);
    }
    {
        ok (-f $epub);
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        my $zip = Archive::Zip->new;
        die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
        $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
          or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
        my $css = read_file(File::Spec->catfile($tmpdir->dirname, "stylesheet.css"));
        my $html_body = read_file($html);
        foreach my $tcss ($css, $html_body) {
            like $tcss, qr/font-family: "DejaVuSerif"/, "Found font-family even if not embedded";
            unlike $tcss, $font_size_in_pt;
        }
        my $manifest = read_file(File::Spec->catfile($tmpdir, "content.opf"));
        foreach my $family (qw/serif sans mono/) {
            foreach my $file (qw/regular.otf bold.otf italic.otf bolditalic.otf/) {
                my $epubfile = File::Spec->catfile($tmpdir, "$family-$file");
                ok (! -f $epubfile, "$epubfile embedded");
                unlike $css, qr/src: url\("\Q$family-$file\E"\) format\(.+\)/, "Found the css rules for $file" or die;
                unlike $manifest, qr/href="\Q$family-$file\E"/, "Found the font in the manifest" or die;
            }
        }
        unlike $manifest, qr{(application/x-font.*){4}}s;
    }
}

# missing sans font in the spec
eval {
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => [ $fonts[0] ],
                                      extra => { mainfont => 'DejaVuSerif' },
                                      pdf => $xelatex);
    $c->purge($muse_file);
    $c->compile($muse_file);
    ok (! -f $tex);
    ok (! -f $epub);
};

# using the default, dummy font passed
eval {
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => [ @fonts ],
                                      extra => { mainfont => 'DejaVuasdfSerif' },
                                      pdf => $xelatex);
    $c->purge($muse_file);
    $c->compile($muse_file);
    is $c->fonts->main->name, 'DejaVuSerif';
    ok (-f $tex);
    ok (-f $epub);
};

# dangerous names in the specification
eval {
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => [ @fonts, { name => 'asdlf/baf', type => 'serif' }],
                                      pdf => $xelatex);
    # trigger the crash
    $c->fonts;
};
ok ($@, "bad specification: $@");

# dangerous names in the specification
eval {
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => [ @fonts, { name => 'asdlfbaf', type => 'serif',
                                                              regular => '/this-can-t-really-exist-i-hope' }],
                                      pdf => $xelatex);
    # trigger the crash
    $c->fonts;
};
ok ($@, "bad specification: $@");

# here we use a fontspec list which, being without the files, sets the
# fonts in the .tex, but not in the EPUB

{
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => [
                                                   map {
                                                       +{
                                                         name => $_->{name},
                                                         type => $_->{type},
                                                        }
                                                   } @fonts
                                                  ],
                                      pdf => $xelatex,
                                      extra => {
                                                mainfont => 'DejaVuSerif',
                                                sansfont => 'DejaVuSans',
                                                monofont => 'DejaVuSansMono',
                                               },
                                     );

    diag Dumper($c->fonts);
    $c->compile($muse_file);
    {
        ok (-f $tex, "$tex produced");
        my $texbody = read_file($tex);
        like $texbody, qr/(mainfont|babelfont\{rm\}).*\{DejaVuSerif\}/;
        like $texbody, qr/(monofont|babelfont\{tt\}).*\{DejaVuSansMono\}/;
        like $texbody, qr/(sansfont|babelfont\{sf\}).*\{DejaVuSans\}/ or die Dumper($c);
    }
  SKIP: {
        skip "No pdf required", 1 unless $xelatex;
        ok (-f $pdf);
    }
    {
        ok (-f $epub);
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        my $zip = Archive::Zip->new;
        die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
        $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
          or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
        my $css = read_file(File::Spec->catfile($tmpdir->dirname, "stylesheet.css"));
        my $html_body = read_file($html);
        foreach my $tcss ($css, $html_body) {
            like $tcss, qr/font-family: "DejaVuSerif"/, "Found font-family even if not embedded";
            unlike $tcss, $font_size_in_pt;
        }
        my $manifest = read_file(File::Spec->catfile($tmpdir, "content.opf"));
        foreach my $family (qw/serif sans mono/) {
            foreach my $file (qw/regular.otf bold.otf italic.otf bolditalic.otf/) {
                my $epubfile = File::Spec->catfile($tmpdir, "$family-$file");
                ok (! -f $epubfile, "$epubfile embedded");
                unlike $css, qr/src: url\("\Q$family-$file\E"\) format\(.+\)/, "Found the css rules for $file" or die;
                unlike $manifest, qr/href="\Q$family-$file\E"/, "Found the font in the manifest" or die;
            }
        }
        unlike $manifest, qr{(application/x-font.*){4}}s;
    }
}


# here is all valid, but we mix main, sans, mono. So people can use a
# sans or even mono font as the main font.

{
    my $c = Text::Amuse::Compile->new(epub => 1, html => 1,
                                      tex => 1,
                                      fontspec => [ @fonts ],
                                      pdf => $xelatex,
                                      extra => {
                                                mainfont => 'DejaVuSansMono',
                                                sansfont => 'DejaVuSerif',
                                                monofont => 'DejaVuSans',
                                               },
                                     );
    diag Dumper(\@fonts);

    $c->compile($muse_file);
    {
        ok (-f $tex, "$tex produced");
        my $texbody = read_file($tex);
        like $texbody, qr/(mainfont|babelfont\{rm\})$font_re/;
        like $texbody, qr/(monofont|babelfont\{tt\})$font_re/;
        like $texbody, qr/(sansfont|babelfont\{sf\})$font_re/ or die Dumper($c);
    }
  SKIP: {
        skip "No pdf required", 1 unless $xelatex;
        ok (-f $pdf, "PDF produced with " . Dumper($c->fonts));
    }
    {
        ok (-f $epub);
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        my $zip = Archive::Zip->new;
        die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
        $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
          or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
        my $css = read_file(File::Spec->catfile($tmpdir->dirname, "stylesheet.css"));
        my $html_body = read_file($html);
        foreach my $tcss ($css, $html_body) {
            like $tcss, qr/font-family: "DejaVuSansMono"/, "Found font-family embedded";
            unlike $tcss, $font_size_in_pt;
        }
        my $manifest = read_file(File::Spec->catfile($tmpdir, "content.opf"));
        foreach my $family (qw/serif sans mono/) {
            foreach my $file (qw/regular.otf bold.otf italic.otf bolditalic.otf/) {
                my $epubfile = File::Spec->catfile($tmpdir, "$family-$file");
                ok (-f $epubfile, "$epubfile embedded");
                like $css, qr/src: url\("\Q$family-$file\E"\) format\(.+\)/, "Found the css rules for $file" or die;
                like $manifest, qr/href="\Q$family-$file\E"/, "Found the font in the manifest" or die;
            }
        }
        like $manifest, qr{(application/x-font.*){4}}s;
    }
}
