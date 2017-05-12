#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

# The encoding of HTML::TreeBuilder is different on different operating systems.
# If this test fails many other tests will fail, too.

use Encode;
use HTML::TreeBuilder;
use HTML::Entities;
use Test::More tests => 4;

sub debug {0}


my $XML_HEADER = qq(<?xml version="1.0" encoding="UTF-8"?>\n);
my %e2c =
    map {$_ => pack("U", ord $HTML::Entities::entity2char{$_})}
    grep {my $value = ord($HTML::Entities::entity2char{$_}); 128 <= $value && $value < 256}
    keys %HTML::Entities::entity2char;

sub utf8 {Encode::is_utf8($_[0]) ? "utf-8" : "nativ"}

sub octet {
    join("",
        map {
            $_ > 255 ?                      # if wide character...
                sprintf("\\x{%04X}", $_)    #     \x{...}
            : $_ > 127 ?                    # if 1xxxxxxx
                sprintf("\\x{%02X}", $_)      #     \x..
            :                               # else
                chr($_)                     #     as themselves
        } unpack("C*", $_[0])
    );
}

sub html_decode_entities_utf8 {
    my ($value) = @_;
    foreach ($value) {
        s/(&\#(\d+);?)/ 128<=$2 && $2<256 ? pack("U", $2) : $1 /eg;
        s/(&\#[xX]([0-9a-fA-F]+);?)/ my $c = hex($2); 128<=$c && $c<256 ? pack("U", $c) : $1 /eg;
        s/(&(\w+);?)/ $e2c{$2} || $1 /eg;
    }
    return $value;
}

sub to_xhtml {
    my ($dirty_html, $encoding) = @_;

    my $parser = new HTML::TreeBuilder();
    $parser->no_space_compacting(1);
    $parser->ignore_ignorable_whitespace(0);

    # Encode $dirty_html to Perls internal encoding UTF-8.
    #$dirty_html = octet_to_internal_utf8($encoding, $dirty_html);
    $dirty_html = Encode::decode($encoding, $dirty_html);

    # Decode HTML entities, because HTML::TreeBuilder doesn't handle it right.
    # Can't use HTML::Entities::decode_entities because it uses 'chr($x)'
    # instead of 'pack("U",$x)'
    $dirty_html = html_decode_entities_utf8($dirty_html);
    print STDERR "DIRTY[", utf8($dirty_html), "]=", octet($dirty_html), "\n" if debug;

    # Parse $dirty_html and encode all remaining bytes as html entities.
    # That works because all non-ASCII UTF-8 character bytes are 1xxxxxxx
    my $tree = $parser->parse($dirty_html);
    my $xml = $XML_HEADER . $tree->as_XML();
    # $xml has all byte encoded as &#xx;
    $tree = $tree -> delete;

    print STDERR "XML[", utf8($xml), "]=", octet($xml), "\n" if debug;
    if (Encode::is_utf8($xml)) { # SunOS
        $xml =~ s/(&\#(\d+);)/ 32 <= $2 && $2 < 128 ? $1 : pack("U", $2) /eg;
    }
    else { # Linux, Win32
        # Decode UTF-8 characters and control characters, $xml is ASCII
        $xml =~ s/(&\#(\d+);)/ 32 <= $2 && $2 < 128 ? $1 : pack("C", $2) /eg;
        # Now we have an UTF-8 string and must Perl believe so too.
        Encode::_utf8_on($xml);
    }


    return $xml;
}

sub check_file {
    my ($filename, $encoding, $assert) = @_;

    local *F;
    open F, "<$filename" or die "Can't open file=$filename, $!";
    binmode F;
    my $content = do {local $/; <F>};
    close F;

    my $xhtml = to_xhtml($content, $encoding);
    $assert->($xhtml);
}


MAIN: {
    check_file("t/xhtml/isolatin-simple.html", "iso-8859-1", sub {
        my ($xhtml) = @_;
        unlike($xhtml, qr/&#\d+;/, "iso-8859-1: No HTML entities");
        $xhtml =~ m/(1111[^3]*3333)/;
        my $out = join ":", unpack("C*", $1);
        is($out, "49:49:49:49:194:160:50:50:50:50:195:134:51:51:51:51",
            "Entities must be utf-8 encoded");
    });
    check_file("t/xhtml/chinese.html", "utf-8", sub {
        my ($xhtml) = @_;
        like($xhtml, qr{<title>\x{76EE}</title>}, "utf-8: chinese character");
        like($xhtml, qr{content="\xE4"}, "utf-8: umlaut");
    });
}

1;
