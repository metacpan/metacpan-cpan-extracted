package Text::Fy::Utils;
$Text::Fy::Utils::VERSION = '0.10';
use 5.020;
use warnings;

use Carp;
use Unicode::Normalize;
use Encode qw(encode decode);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(asciify isoify simplify commify cv_to_win cv_from_win);

my %cp1252_to_uni;

for (128..159) {
    $cp1252_to_uni{chr($_)} = decode('cp1252', chr($_));
}

my %uni_to_ascii = (
  "\x{20ac}" => q{E},
  "\x{201a}" => q{,},
  "\x{0192}" => q{f},
  "\x{2026}" => q{_},
  "\x{2020}" => q{+},
  "\x{02c6}" => q{^},
  "\x{2030}" => q{%},
# "\x{0160}" => q{S},
  "\x{2039}" => q{<},
  "\x{0152}" => q{O},
# "\x{017d}" => q{Z},
  "\x{2022}" => q{.},
  "\x{20dc}" => q{~},
# "\x{0161}" => q{s},
  "\x{203a}" => q{>},
  "\x{203a}" => q{>},
  "\x{0153}" => q{o},
# "\x{017e}" => q{z},
# "\x{017e}" => q{Y},
  "\x{0080}" => q{e},
  "\x{0082}" => q{,},
  "\x{0083}" => q{f},
  "\x{0085}" => q{_},
  "\x{0088}" => q{^},
  "\x{0089}" => q{%},
  "\x{008b}" => q{<},
  "\x{008c}" => q{O},
  "\x{0095}" => q{.},
  "\x{0098}" => q{~},
  "\x{0099}" => q{T},
  "\x{009b}" => q{>},
  "\x{009c}" => q{o},
  "\x{00a1}" => q{!},
  "\x{00a2}" => q{c},
  "\x{00a3}" => q{L},
  "\x{00a5}" => q{Y},
  "\x{00a6}" => q{|},
  "\x{00a9}" => q{C},
  "\x{00aa}" => q{a},
  "\x{00ae}" => q{R},
  "\x{00b2}" => q{2},
  "\x{00b3}" => q{3},
  "\x{00b7}" => q{.},
  "\x{00b9}" => q{1},
  "\x{00ba}" => q{0},
  "\x{00bf}" => q{?},
  "\x{00c6}" => q{A},
  "\x{00d7}" => q{x},
  "\x{00d8}" => q{O},
  "\x{00df}" => q{s},
  "\x{00e6}" => q{a},
  "\x{00f0}" => q{d},
  "\x{00f8}" => q{o},
);

my %uni_to_iso = (
  "\x{201c}" => q{"},
  "\x{201d}" => q{"},
  "\x{201e}" => q{"},

  "\x{2018}" => q{'},
  "\x{2019}" => q{'},

  "\x{2013}" => q{-},
  "\x{2014}" => q{-},
);

my %iso_to_ascii = (
  "\x{008a}" => q{S},
  "\x{008e}" => q{Z},
  "\x{009a}" => q{s},
  "\x{009e}" => q{z},
  "\x{009f}" => q{Y},
  "\x{00ba}" => q{o},

  "\x{0084}" => q{"},
  "\x{0093}" => q{"},
  "\x{0094}" => q{"},
  "\x{00ab}" => q{"},
  "\x{00bb}" => q{"},

  "\x{0091}" => q{'},
  "\x{0092}" => q{'},
  "\x{00b4}" => q{'},

  "\x{0096}" => q{-},
  "\x{0097}" => q{-},
  "\x{00ac}" => q{-},
  "\x{00ad}" => q{-},
);

my $convert_c2u = _make_tr(\%cp1252_to_uni);
my $convert_u2c = _make_tr(\%cp1252_to_uni, 'R');
my $convert_u2a = _make_tr(\%uni_to_ascii);
my $convert_u2i = _make_tr(\%uni_to_iso);
my $convert_i2a = _make_tr(\%iso_to_ascii);

sub _make_tr {
    my ($href, $rev) = @_;

    my $from = join '', map { sprintf '\x{%04x}', ord($_)          } sort keys %$href;
    my $to   = join '', map { sprintf '\x{%04x}', ord($href->{$_}) } sort keys %$href;

    my $code = 'sub { $_[0] =~ '.($rev ? "tr/$to/$from/" : "tr/$from/$to/").'; }';

    eval $code or die "Can't compile >$code< because $@";
}

sub asciify {
    _aconvert($_[0], 0, 0);
}

sub isoify {
    _aconvert($_[0], 1, 0);
}

sub simplify {
    _aconvert($_[0], 2, 0);
}

sub _aconvert {
    my ($text, $loc_m, $loc_w) = @_;

    $convert_u2i->($text);

    if ($loc_w) { # windows cp1252
        $convert_c2u->($text);
    }

    if ($loc_m == 1) { # iso
        $text = NFC($text) =~ s{\p{Diacriticals}}''xmsgr;

        if ($loc_w) { # windows cp1252
           $convert_u2c->($text);
        }

        $text =~ s{([^\x00-\xff])}{NFD($1)}xmsge;

        $text =~ s{\p{Diacriticals}}''xmsg;

        $text = encode('iso-8859-1', $text);
    }
    else { # pure or brutal
        $convert_i2a->($text);
        $convert_u2a->($text) if $loc_m == 2; # brutal

        $text = encode('iso-8859-1', NFD($text) =~ s{\p{Diacriticals}}''xmsgr);
        $text =~ s{\P{ASCII}}'?'xmsg;
    }

    return $text;
}

sub cv_from_win {
    my ($buf) = @_;

    $convert_c2u->($buf);

    return $buf;
}

sub cv_to_win {
    my ($buf) = @_;

    $convert_u2c->($buf);

    return $buf;
}

sub commify {
    local $_ = shift;
    my ($sep) = @_;

    $sep //= '_';

    my $len = length($_);
    for my $i (1..$len) {
        last unless s/^([-+]?\d+)(\d{3})/$1$sep$2/;
    }

    return $_;
}

1;

__END__

=head1 NAME

Text::Fy::Utils - Some text based utility functions

=head1 SYNOPSIS

    use Text::Fy::Utils qw(
      asciify isoify simplify commify
      cv_from_win cv_to_win
    );

    my $t1 =
      "\x{041}\x{062}\x{043} => ".
      "\x{08a}\x{08c}\x{08e} => ".
      "\x{091}\x{092}\x{093} => ".
      "\x{0a1}\x{0a2}\x{0bf} => ".
      "\x{0bc}\x{0bd}\x{0be} => ".
      "\x{0c6}\x{0c7}\x{0c8} => ";

    my $t2 =
      "\x{172}\x{173}\x{174} => ".
      "\x{388}\x{389}\x{38a} => ".
      "\x{3b1}\x{3b2}\x{3b3} => ";

    my $asc6 = simplify($t1.$t2);
    my $asc7 = asciify($t1.$t2);
    my $asc8 = isoify($t1.$t2);

    my $out1 = commify('12345678.1234');
    my $out2 = commify('12345678.1234', '~');

    my $out3 = cv_from_win($t1.$t2);
    my $out4 = cv_to_win($t1.$t2);

=head1 OTHER REFERENCES

There is a list of all unicode names in ...\perl\lib\unicore\Name.pl

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
