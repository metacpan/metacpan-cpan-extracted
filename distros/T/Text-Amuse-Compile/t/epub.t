#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 37;
use File::Spec;
use Text::Amuse::Compile;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp;
use Text::Amuse::Compile::Utils qw/read_file write_file/;

my $cover = File::Spec->rel2abs(File::Spec->catfile(qw/t manual logo.png/));

ok (-f $cover, "$cover is here");

my $c = Text::Amuse::Compile->new(epub => 1,
                                  extra => { cover  => $cover,
                                             coverwidth => 0.70,
                                           });

my $target_base = File::Spec->catfile(qw/t testfile for-epub/);

$c->compile($target_base . '.muse');

my $epub = $target_base . '.epub';

die "No epub produced, cannot continue!" unless -f $epub;

# let's inspect the damned thing

my $zip = Archive::Zip->new;
die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);

diag "Using " .$tmpdir->dirname;

$zip->extractTree('OPS', $tmpdir->dirname);

foreach my $file (qw/piece000001.xhtml
                     piece000002.xhtml
                     piece000003.xhtml
                     titlepage.xhtml/) {
    my $page = read_file(File::Spec->catfile($tmpdir->dirname,
                                             $file));
    like $page, qr{<title>.*\&amp\;.*\&amp\;.*</title>}, "Title escaped on $file";
    like $page, qr{\&amp\;.*\&amp\;}, "& escaped on $file";
    if ($file =~ m/piece000/) {
        like $page, qr{<a id="text-amuse-label}, "Found anchor";
    }
    if ($file eq 'piece000003.xhtml') {
        my $exp = '<a class="text-amuse-link" href="piece00000';
        for my $num (1..3) {
            my $explink = $exp . $num . '.xhtml#text-amuse-label-';
            like $page, qr{\Q$explink\E}, "Found href $explink";
        }
    }
    unlike $page, qr{\& }, "no lonely & on $file";
    if ($page =~ m{<title>(.*)</title>}) {
        my $title = $1;
        unlike $title, qr{[<>"']}, "Title: $title escaped";
    }
    else {
        die "No title on $file";
    }
}

{
    my $css = read_file(File::Spec->catfile($tmpdir->dirname,
                                            'stylesheet.css'));
    unlike($css, qr/div#page\s*\{\s*margin:20px;\s*padding:20px;\s*\}/s,
                 "Found the margins in the CSS");
    like($css, qr/\@page/, "\@page found");
    like($css, qr/text-align: justify/, "Justify found in the body");
    unlike($css, qr/\@font-face/, "\@font-face not found");
    unlike($css, qr{font-size:.*pt}, "Font side not set");
    like($css, qr/font-family: "CMU Serif", serif;/, "Found the serif font family");

}

{
    my $manifest = read_file(File::Spec->catfile($tmpdir->dirname,
                                                 'content.opf'));
    like ($manifest, qr{href="attachment.png" media-type="image/png"});
    like ($manifest, qr{href="logo.png" media-type="image/png"});
    like ($manifest, qr{<meta name="cover" content="id1" />});
    like ($manifest, qr{<guide>\s*<reference href="coverpage.xhtml"\s*type="cover"}s);
    ok (-f File::Spec->catfile($tmpdir->dirname, 'logo.png'), "Found logo.png");
}

{
    my $titlepage = read_file(File::Spec->catfile($tmpdir->dirname,
                                                  'titlepage.xhtml'));
    like ($titlepage, qr{pinco.*pallino.*tizio}, "titlepage has the author");
    unlike ($titlepage, qr{src="logo.png"}, "titlepage has no image");
}

{
    my $coverpage = read_file(File::Spec->catfile($tmpdir->dirname,
                                                  'coverpage.xhtml'));
    like ($coverpage, qr{xlink:href="logo.png"}, "coverpage has the image");
}
