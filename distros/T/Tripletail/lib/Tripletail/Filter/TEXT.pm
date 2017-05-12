# -----------------------------------------------------------------------------
# Tripletail::Filter::TEXT - テキスト出力フィルタ
# -----------------------------------------------------------------------------
package Tripletail::Filter::TEXT;
use strict;
use warnings;
use Tripletail;
use base 'Tripletail::Filter::Cookie';

# オプション一覧:
# * charset     => 出力の文字コード。(UTF-8から変換される)
#                  (絵文字使用不可)
#                  デフォルト: Shift_JIS
# * contenttype => デフォルト: text/plain; charset=(CHARSET)

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	local($_);

	# Contentが1バイトでも出力されたかどうか
	$this->{content_printed} = undef;

	# デフォルト値を埋める。
		my $defaults = [
		[charset     => 'Shift_JIS'],
		[contenttype => sub {
			# 動的に決まるのでCODE Refを渡す。引数は取らない。
			sprintf 'text/plain; charset=%s', $this->{option}{charset};
		}],
	];
	$this->_fill_option_defaults($defaults);

	# オプションのチェック
	my $check = {
		charset     => [qw(defined no_empty scalar)],
		contenttype => [qw(defined no_empty scalar)],
	};
	$this->_check_options($check);

	$this->setHeader('Content-Type' => $this->{option}{contenttype});

	$this;
}

sub print {
	my $this = shift;
	my $data = shift;
	my $output = $this->_flush_header;

	if(ref($data)) {
		die __PACKAGE__."#print: arg[1] is a reference. [$data] (第1引数がリファレンスです)\n";
	}

	$output .= $TL->charconv($data, 'utf8' => $this->{option}{charset});

	if(length($output)) {
		$this->{content_printed} = 1;
	}

	$output;
}

sub flush {
	my $this = shift;

	if(!$this->{content_printed}) {
		die __PACKAGE__."#flush: no contents have been printed during this request. (リクエスト処理で何もprintされていません)\n";
	}

	'';
}

sub reset {
	my $this = shift;
	$this->SUPER::reset;

	$this->{content_printed} = undef;

	$this->setHeader('Content-Type' => $this->{option}{contenttype});

	$this;
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::Filter::TEXT - テキスト出力フィルタ

=head1 SYNOPSIS

  $TL->setContentFilter('Tripletail::Filter::TEXT', charset => 'UTF-8');

  $TL->print($TL->readTextFile('foo.txt'));

=head1 DESCRIPTION

テキストの出力を支援する。

=head2 フィルタパラメータ

=over 4

=item charset

出力文字コードを指定する。省略可能。

使用可能なコードは次の通り。
UTF-8，Shift_JIS，EUC-JP，ISO-2022-JP

デフォルトはShitf_JIS。

=item contenttype

  $TL->setContentFilter('Tripletail::Filter::TEXT', contenttype => 'text/plain; charset=Shift_JIS');

Content-Typeを指定する。省略可能。

デフォルトはtext/plain; charset=（charsetで指定された文字コード）。

=back

=head2 METHODS

=over 4

=item setHeader

  $filter->setHeader($key => $value)

他の出力の前に実行する必要がある。
同じヘッダを既に出力しようとしていれば、そのヘッダの代わりに指定したヘッダを出力する。（上書きされる）

=item addHeader

  $filter->addHeader($key => $value)

他の出力の前に実行する必要がある。
同じヘッダを既に出力しようとしていれば、そのヘッダに加えて指定したヘッダを出力する。（追加される）

=item flush

L<Tripletail::Filter>参照

=item print

L<Tripletail::Filter>参照

=item reset

L<Tripletail::Filter>参照

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Filter>

=item L<Tripletail::Filter::CSV>

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
