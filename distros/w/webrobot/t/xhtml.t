#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::Html2XHtml;
use Test::More tests => 8;

MAIN: {
    check_file("t/xhtml/isolatin-simple.html", "iso-8859-1", sub {
        my ($xhtml) = @_;
        unlike($xhtml, qr/&#\d+;/, "iso-8859-1: No HTML entities");
        $xhtml =~ m/(1111[^3]*3333)/;
        my $out = join ":", unpack("C*", $1);
        is($out, "49:49:49:49:194:160:50:50:50:50:195:134:51:51:51:51",
            "Entities must be utf-8 encoded");
    });
    check_file("t/xhtml/isolatin.html", "iso-8859-1", sub {
        my ($xhtml) = @_;
        like($xhtml, qr{<title>\xE4</title>}, "iso-8859-1: umlaut");
        like($xhtml, qr/value="\&\#38;\&\#60;\&\#62;"/,
            'iso-8859-1: XML entities &<> allowed and required');
    });
    check_file("t/xhtml/isolatin-doctype.html", "iso-8859-1", sub {
        my ($xhtml) = @_;
        like($xhtml, qr{<title>\xE4</title>}, "iso-8859-1: umlaut");
        unlike($xhtml, qr/DOCTYPE/, "iso-8859-1: DOCTYPE removed");
    });
    check_file("t/xhtml/chinese.html", "utf-8", sub {
        my ($xhtml) = @_;
        like($xhtml, qr{<title>\x{76EE}</title>}, "utf-8: chinese character");
        like($xhtml, qr{content="\xE4"}, "utf-8: umlaut");
    });
}


sub check_file {
    my ($filename, $encoding, $assert) = @_;

    local *F;
    open F, "<$filename" or die "Can't open file=$filename, $!";
    binmode F;
    my $content = do {local $/; <F>};
    close F;

    my $parser = WWW::Webrobot::Html2XHtml->new();
    my $xhtml = $parser->to_xhtml($content, $encoding);
    $assert->($xhtml);
}

1;
