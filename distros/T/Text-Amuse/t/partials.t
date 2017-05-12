#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 38;
use Text::Amuse;
use File::Temp;
use Data::Dumper;

my $muse = <<'MUSE';
#title The title
#author The author

First chunk (0)

* First part (1)

First part body (1)

** First chapter (2)

First chapter body (2)

*** First section (3)

First section body (3)

**** First subsection (4)

First subsection (4)

 Item :: Blabla (4)

* Second part (5)

Second part body (5)

** Second chapter (6)

Second chapter body (6)

*** Second section (7)

Second section body (7)

**** Second subsection (8)

Second subsection (8)

 Item :: Blabla

*** Third section (9)

Third section (9)

 Item :: Blabla

*** Fourth section (10)

Blabla (10)

MUSE

my $fh = File::Temp->new(SUFFIX => '.muse');
binmode $fh, ':encoding(utf-8)';
print $fh $muse;
close $fh;

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename, partial => 'bla') };
    ok ($@, "Found exception $@");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => { bla => 1 }) };
    ok ($@, "Found exception $@");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => [qw/a b/]) };
    ok ($@, "Found exception $@");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => []) };
    ok (!$doc->partials, "No partials found with empty list");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => [qw/0 1 3 9 100/]) };
    ok (!$@, "doc created") or diag $@;
    ok $doc;
    is_deeply($doc->partials, { 0 => 1, 1 => 1, 3 => 1, 9 => 1, 100 => 1 },
              "Partials are good");
    foreach my $method (qw/as_splat_html as_splat_latex/) {
        my @chunks = $doc->$method;
        is (scalar(@chunks), 4, "Found 4 chunks");
        my @toc = $doc->raw_html_toc;
        is (scalar(@toc), scalar(@chunks), "Toc matches!");
        like ($chunks[0], qr{\(0\)}s);
        like ($chunks[1], qr{\(1\).*\(1\)}s);
        like ($chunks[2], qr{\(3\).*\(3\)}s);
        like ($chunks[3], qr{\(9\).*\(9\)}s);
    }
    foreach my $method (qw/as_html as_latex/) {
        my $body = $doc->$method;
        like $body, qr{\(0\).*\(1\).*\(1\).*\(3\).*\(3\).*\(9\).*\(9\)}s, "$method ok with keys";
        unlike $body, qr{\([245678]+\)}, "full $method without excluded kes ok";
    }
    like $doc->toc_as_html, qr{toc1.*toc3.*toc9}s, "toc as 1,3,9 anchors";
    unlike $doc->toc_as_html, qr{toc0}, "toc is missing the 0 anchor";
    unlike $doc->toc_as_html, qr{toc[245678]}, "toc is missing the other anchors";
    ok !$doc->wants_preamble, "Preamble not wanted";
    ok !$doc->wants_postamble, "Postamble not wanted";
}

{
    my $doc = Text::Amuse->new(file => $fh->filename);
    ok $doc->wants_preamble, "Preamble wanted";
    ok $doc->wants_postamble, "Postamble wanted";
}

{
    my $doc = Text::Amuse->new(file => $fh->filename, partial => [qw/0 9/]);
    ok !$doc->wants_preamble, "Preamble not wanted";
    ok !$doc->wants_postamble, "Postamble not wanted";
}

{
    my $doc = Text::Amuse->new(file => $fh->filename, partial => [qw/pre 0 9/]);
    ok $doc->wants_preamble, "Preamble wanted";
    ok !$doc->wants_postamble, "Postamble not wanted";
}

{
    my $doc = Text::Amuse->new(file => $fh->filename, partial => [qw/post 0 9/]);
    ok !$doc->wants_preamble, "Preamble not wanted";
    ok $doc->wants_postamble, "Postamble wanted";
}
{
    my $doc = Text::Amuse->new(file => $fh->filename, partial => [qw/pre post 3/]);
    ok $doc->wants_preamble, "Preamble wanted";
    ok $doc->wants_postamble, "Postamble wanted";
}
