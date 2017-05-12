# -----------------------------------------------------------------------------
# Tripletail::Filter::CSV - CSV出力フィルタ
# -----------------------------------------------------------------------------
package Tripletail::Filter::CSV;
use strict;
use warnings;
use Tripletail;
use Tripletail::CharConv;
use base 'Tripletail::Filter::Cookie';

# オプション一覧:
# * charset     => 出力の文字コード。(UTF-8から変換される)
#                  Encode.pmが利用可能なら利用する。(UniJP一部互換エンコード名、sjis絵文字使用不可)
#                  デフォルト: Shift_JIS
# * contenttype => デフォルト: text/csv; charset=(CHARSET)
# * filename    => 指定されると、そのファイル名で Content-Disposition を出力する。

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	# Contentが1バイトでも出力されたかどうか
	$this->{content_printed} = undef;

	# デフォルト値を埋める。
	my $defaults = [
		[linebreak   => "\r\n"],
		[charset     => 'Shift_JIS'],
		[contenttype => sub {
			# 動的に決まるのでCODE Refを渡す。引数は取らない。

			my $ctype;
			$ctype = sprintf 'text/csv; charset=%s', $this->{option}{charset};

			if(defined($this->{option}{filename})) {
				$ctype .= qq{; name="$this->{option}{filename}"};
			}
			$ctype;
		}],
	];
	$this->_fill_option_defaults($defaults);

	# オプションのチェック
	my $check = {
		linebreak   => [qw(defined no_empty scalar)],
		charset     => [qw(defined no_empty scalar)],
		contenttype => [qw(defined no_empty scalar)],
		filename    => [qw(no_empty scalar)],
	};
	$this->_check_options($check);

	$this->setHeader('Content-Type' => $this->{option}{contenttype});

	if(defined($this->{option}{filename})) {
		my $filename = $this->{option}{filename};
		$filename = $TL->charconv($filename, 'UTF-8' => $this->{option}{charset});
		$this->setHeader('Content-Disposition' => qq{attachment; filename="$filename"});
	}

	$this;
}

sub print {
	my $this = shift;
	my $data = shift;
	my $output = $this->_flush_header;

	if (ref($data)) {
		if (ref($data) eq 'ARRAY') {
			$data = $TL->getCsv->makeCsv($data) . $this->{option}{linebreak};
		}
		else {
			die __PACKAGE__."#print: arg[1] is neither a SCALAR nor an ARRAY Ref. [$data] (第1引数がスカラでも配列のリファレンスでもありません)\n";
		}
	}

	$output .= $TL->charconv($data, 'utf8' => $this->{option}{charset});

	if (length($output)) {
		$this->{content_printed} = 1;
	}

	$output;
}

sub flush {
	my $this = shift;

	if(!$this->{content_printed}) {
		die __PACKAGE__."#flush: no contents has been printed during this request. (リクエスト処理で何もprintされていません)\n";
	}

	'';
}

sub reset {
	my $this = shift;
	$this->SUPER::reset;

	$this->{content_printed} = undef;

	$this->setHeader('Content-Type' => $this->{option}{contenttype});

	if(defined($this->{option}{filename})) {
		my $filename = $this->{option}{filename};
		$filename = $TL->charconv($filename, 'UTF-8' => $this->{option}{charset});
		$this->setHeader('Content-Disposition' => qq{attachment; filename="$filename"});
	}

	$this;
}

__END__

=encoding utf-8

=for stopwords
	CSV
	YMIRLINK
	addHeader
	contenttype
	linebreak
	setHeader

=head1 NAME

Tripletail::Filter::CSV - CSV 出力フィルタ

=head1 SYNOPSIS

  $TL->setContentFilter(
      'Tripletail::Filter::CSV',
      charset  => 'UTF-8',
      filename => 'foo.csv',
  );

  $TL->print('aaa,"b,b,b",ccc,ddd' . "\r\n");
  $TL->print(['aaa', 'b,b,b', 'ccc', 'ddd']);

=head1 DESCRIPTION

CSV の出力を支援する。

ファイル名の指定で Content-Disposition を出力可能。

また、このフィルタの使用時には、L<< $TL->print|Tripletail/"print" >>
に文字列の配列を渡す事も出来る。配列が渡された場合は、各要素を
必要に応じて "" で囲み、カンマで繋げ、改行コードを付けて出力する。

文字列を渡す場合は、改行コードは付与されないことに注意。

=head2 フィルタパラメータ

=over 4

=item charset

出力文字コードを指定する。省略可能。

使用可能なコードは次の通り。
UTF-8，Shift_JIS，EUC-JP，ISO-2022-JP
	
デフォルトはShitf_JIS。

=item contenttype

  $TL->setContentFilter('Tripletail::Filter::CSV', contenttype => 'text/html; charset=sjis');

C<Content-Type> を指定する。省略可能。

デフォルトはtext/csv; charset=（charasetで指定された文字コード）。

=item linebreak

配列が渡されたときに、どのような改行コードを利用するかを指定する。省略可能。

デフォルトは "\r\n"。

=item filename

ヘッダで出力するファイル名を指定する。省略可能。
指定した場合、次のようなヘッダが出力される。

  Content-Type: text/csv; charset=Shift_JIS; name="foo.csv"
  Content-Disposition: attachment; filename="foo.csv"

指定しない場合は、次のようなヘッダが出力される。

  Content-Type: text/csv; charset=Shift_JIS

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

=item L<Tripletail::Filter::TEXT>

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
