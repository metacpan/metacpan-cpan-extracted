# -----------------------------------------------------------------------------
# Tripletail::InputFilter::MobileHTML - 携帯電話向けHTML用CGIクエリ読み取り
# -----------------------------------------------------------------------------
package Tripletail::InputFilter::MobileHTML;
use base 'Tripletail::InputFilter::HTML';
use strict;
use warnings;
use Tripletail;

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	$this;
}

sub decodeCgi {
	my $this = shift;
	my $form = shift;

	binmode(STDIN);
	my $newform = $this->_formFromPairs(
	$this->__pairsFromCgiInput);

	$form->addForm($newform);

	if(defined(&Tripletail::Session::_getInstance)) {
		# ここで必要に応じてセッションをフォームから読み出す。
		foreach my $group (Tripletail::Session->_getInstanceGroups) {
			Tripletail::Session->_getInstance($group)->_getSessionDataFromForm($form);
		}
	}

	$this;
}

sub _getIncode {
	# CCCよりもUser-Agentからの情報を優先する。
	my $this = shift;
	my $pairs = shift;

	my $CCC;
	for(my $i = 0; $i < @$pairs; $i++) {
		if($pairs->[$i][0] eq 'CCC' && $pairs->[$i][1]) {
			$CCC = $pairs->[$i][1];

			splice @$pairs, $i, 1; # CCCをpairsから消す
			last;
		}
	}

	# 文字コードが指定されていたらそれを使用
	my $charset = $TL->INI->get('InputFilter' => charset => undef);

	if(defined($charset)) {
		return $charset;
	}

	if (my $charset = $TL->newValue($ENV{HTTP_USER_AGENT})->detectMobileAgent()) {
		return $charset;
	}

	if (defined $CCC) {
		$this->_getIncodeFromCCC($CCC);
	}
	else {
		'auto';
	}
}

sub _raw2utf8 {
	my $this = shift;
	my $str = shift;
	my $incode = shift;

	$TL->charconv($str, $incode => 'utf8', 1);
}


__END__

=encoding utf-8

=for stopwords
	CGI
	MySQL
	Unicode
	UTF
	UTF-8
	YMIRLINK
	decodeCgi

=head1 NAME

Tripletail::InputFilter::MobileHTML - 携帯電話向け HTML 用 CGI クエリ読み取り

=head1 SYNOPSIS

  $TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
  
  $TL->startCgi(
      -main => \&main,
  );
  
  sub main {
      if ($CGI->get('mode') eq 'Foo') {
          ...
      }
  }

=head1 DESCRIPTION

以下の点を除いて L<Tripletail::InputFilter::HTML> と同様。

=over 4

=item 絵文字変換

携帯電話の機種毎の絵文字の違いに対応する為に、C<< User-Agent >> を見て
機種を判別し、常に Unicode::Japanese を利用して文字コード変換を行う。

絵文字は Unicode のプライベート領域にマップされる。

プライベート領域の文字は、 UTF-8 にしたときは１文字４バイトとなるので、
DB 等に格納する際はサイズに注意する必要がある。
また、DB の Unicode 対応の範囲外となっている場合、文字化け等することが
あるので、 UTF-8 文字列をバイナリとして DB に保存することを推奨する。
（ MySQL であれば、tinyblob/blob/mediumblob/longblob 型を利用する。）


=item L<セッション|Tripletail::Session>

セッションキーはクッキーでなくクエリから読み取る。

=back

=head2 METHODS

=over 4

=item decodeCgi

内部メソッド

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::InputFilter>

=item L<Tripletail::InputFilter::HTML>

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
# vim:set sw=8 sts=8 ts=8 noet:
