# -----------------------------------------------------------------------------
# Tripletail::CharConv - 文字コードクラス（内部用）
# -----------------------------------------------------------------------------
package Tripletail::CharConv;
use strict;
use warnings;
use Encode;
use Encode::Alias;
use Unicode::Japanese ();

# $TL->charconv('文字列', 'utf8', 'sjis');

our $INSTANCE;
our %MAP_ENCODE_TO_UNIJP = (
	'UTF-8' => 'utf8',
	'ISO-2022-JP' => 'jis',
	'Shift_JIS' => 'sjis',
	'CP932' => 'sjis',
	'EUC-JP' => 'euc',
	'UCS-2' => 'ucs2',
	'UTF-32' => 'ucs4',
	'UTF-16' => 'utf16',
	'UTF-32' => 'utf32',
	'UTF-16BE' => 'utf16-be',
	'UTF-16LE' => 'utf16-le',
	'UTF-32BE' => 'utf32-be',
	'UTF-32LE' => 'utf32-le',
   );
our %UNICODE_JAPANESE_CODE;
our @UNICODE_JAPANESE_CODE = qw(
	auto
	utf8 ucs2 ucs4 utf16-be utf16-le utf16 utf32-be utf32-le utf32
	jis euc euc-jp sjis cp932
	sjis-imode sjis-imode1 sjis-imode2
	sjis-doti sjis-doti1
	sjis-jsky sjis-jsky1 sjis-jsky2
	jis-jsky jis-jsky1 jis-jsky2
	utf8-jsky utf8-jsky1 utf8-jsky2
	jis-au jis-au1 jis-au2
	sjis-au sjis-au1 sjis-au2
	sjis-icon-au sjis-icon-au1 sjis-icon-au2
	euc-icon-au euc-icon-au1 euc-icon-au2
	jis-icon-au jis-icon-au1 jis-icon-au2
	utf8-icon-au utf8-icon-au1 utf8-icon-au2
	ascii
	binary
);


1;

sub _getInstance {
	my $class = shift;

	if (!$INSTANCE) {
		$INSTANCE = $class->__new(@_);
		foreach my $code (@UNICODE_JAPANESE_CODE) {
			$UNICODE_JAPANESE_CODE{$code} = 1;
		}
	}

	$INSTANCE;
}

sub _charconv {
    my $this = shift;
    my $str  = shift;
    my $from = shift;
    my $to   = shift;

    if (!defined $str) {
        die "TL#charconv: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $str) {
        die "TL#charconv: arg[1] is a reference. [$str] (第1引数がリファレンスです)\n";
    }

    if (!defined $from) {
        $from = 'auto';
    }
    elsif (ref $from) {
        die "TL#charconv: arg[2] is a reference. [$from] (第2引数がリファレンスです)\n";
    }

    if (!defined $to) {
        $to = 'UTF-8';
    }
    elsif (ref $to) {
        die "TL#charconv: arg[3] is a reference. [$to] (第3引数がリファレンスです)\n";
    }

    my $fromuj = $MAP_ENCODE_TO_UNIJP{$from} ? $MAP_ENCODE_TO_UNIJP{$from} : $from;
    my $touj   = $MAP_ENCODE_TO_UNIJP{$to  } ? $MAP_ENCODE_TO_UNIJP{$to  } : $to;

    if ($UNICODE_JAPANESE_CODE{$fromuj} and $UNICODE_JAPANESE_CODE{$touj}) {
        # 両方ともUniJPのサポート内ならUniJPで変換
        return Unicode::Japanese->new($str, $fromuj)->conv($touj);
    }
    elsif ($UNICODE_JAPANESE_CODE{$fromuj}) {
        # 片方サポートなのでutf8経由で変換
        my $utf8 = Unicode::Japanese->new($str, $fromuj)->utf8;
        return Encode::find_encoding($to)->encode($utf8);
    }
    elsif ($UNICODE_JAPANESE_CODE{$touj}) {
        # 片方サポートなのでutf8経由で変換
        my $utf8 = Encode::find_encoding($from)->decode($str);
        return Unicode::Japanese->new($str, 'utf8')->conv($touj);
    }
    else {
        # 両方ともサポート外
        my $utf8 = Encode::find_encoding($from)->decode($str);
        return Encode::find_encoding($to)->encode($utf8);
    }
}

sub __new {
    my $class = shift;
    my $this  = bless {} => $class;

    return $this;
}


__END__

=encoding utf-8

=for stopwords
	YMIRLINK

=head1 NAME

Tripletail::CharConv - 内部クラス

=head1 DESCRIPTION

L<Tripletail> によって内部的に使用される。

=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
