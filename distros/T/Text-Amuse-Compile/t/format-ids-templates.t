#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Templates;
use Path::Tiny;
use Data::Dumper;
use Test::More tests => 2;

my $wd = Path::Tiny->tempdir;
my $muse = <<'MUSE';
#title My title

*Test*
MUSE

my $file = $wd->child('test.muse');
$file->spew($muse);


my $ttdir = $wd->child('templates');
$ttdir->mkpath;


$ttdir->child('c9-latex.tt')->spew("This is my template \n\n[% latex_body %]\n");
$ttdir->child('c9-html.tt')->spew("This is my HTML [% doc.as_html %] \n");

my $c = Text::Amuse::Compile->new(tex => 1,
                                  ttdir => "$ttdir",
                                  html => 1,
                                  extra => {
                                            format_id => 'c9',
                                           });
$c->compile("$file");
{
    my $out = $wd->child('test.tex');
    like $out->slurp_utf8, qr{\AThis is my template\s*\\emph\{Test\}\s*}s;
}
{
    my $out = $wd->child('test.html');
    like $out->slurp_utf8, qr{^This is my HTML}s;
}



