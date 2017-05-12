# -----------------------------------------------------------------------------
# Tripletail::InputFilter - CGIクエリパラメータを読み取る
# -----------------------------------------------------------------------------
package Tripletail::InputFilter;
use strict;
use warnings;
use Tripletail;

1;

sub _new {
	my $class = shift;
	my $this = bless {} => $class;

	$this;
}

sub _formFromPairs {
	# 戻り値: Tripletail::Form
	my $this = shift;
	my $pairs = shift;
	my $filename_h = shift;

	my $incode = $this->_getIncode($pairs);

	my $form = $TL->newForm;
	foreach my $pair (@$pairs) {
		my ($key, $value) = @$pair;

		if( exists($filename_h->{$key}) )
		{
			# このキーに対するファイル名が存在する。
			$form->setFileName(
				$this->_raw2utf8($key => $incode) => $this->_raw2utf8($filename_h->{$key} => $incode));
		}

		if (ref $value) {
			$form->setFile(
				$this->_raw2utf8($key => $incode) => $value);
		}
		else {
			$form->add(
				$this->_raw2utf8($key => $incode) => $this->_raw2utf8($value => $incode)
			);
		}
	}

	$form;
}

sub _raw2utf8 {
	my $this = shift;
	my $str = shift;
	my $incode = shift;

	$TL->charconv($str, $incode => 'utf8');
}

sub _getIncode {
	# 戻り値: UniJP文字コード名
	my $this = shift;
	my $pairs = shift;

	# CCCを探し、文字コードを判定。
	my $CCC;
	for(my $i = 0; $i < @$pairs; $i++) {
		if($pairs->[$i][0] eq 'CCC' && $pairs->[$i][1]) {
			$CCC = $pairs->[$i][1];

			splice @$pairs, $i, 1; # CCCをpairsから消す
			last;
		}
	}

	# 文字コードが指定されていたらそれを使用
	my $charset = $TL->INI->get('InputFilter' => 'charset' => undef);

	if(defined($charset)) {
		$charset;
	}
	elsif(defined($CCC)) {
		$this->_getIncodeFromCCC($CCC);
	} else {
		'auto';
	}
}

sub _getIncodeFromCCC {
	# 戻り値: 文字コード名
	my $this = shift;
	my $CCC = shift;

	my $table = {
		"\xb0\xa6" => 'EUC-JP',
		"\x88\xa4" => 'Shift_JIS',
		"\xe6\x84\x9b" => 'UTF-8',
		"\x61\x1b" => 'UCS-2',
	};

	if(my $code = $table->{$CCC}) {
		$code;
	} elsif ($CCC =~ /\x30\x26/) {
		'ISO-2022-JP';
	} else {
		'auto';
	}
}

sub _urlDecodeString {
	my $this = shift;
	my $str = shift;

	$str =~ tr/+/ /;
	$str =~ s{\%([0-9a-fA-F][0-9a-fA-F])|\%u([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])}{
		defined($1) ? pack("C", hex($1)) : pack("n", hex($2));
	}eg;
	$str =~ s/\r\n/\n/g; # Win -> UNIX
	$str =~ s/\r/\n/g; # Mac -> UNIX

	$str;
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::InputFilter - CGIクエリパラメータを読み取る

=head1 SYNOPSIS

  $TL->setInputFilter('Tripletail::InputFilter::HTML');
  
  $TL->startCgi(
      -main => \&main,
  );
  
  sub main {
      if ($CGI->get('mode') eq 'Foo') {
          ...
      }
  }

=head1 DESCRIPTION

QUERY_STRING, PATH_INFO, stdin等からリクエストのパラメータを受け取り、
L<Tripletail::Form> を生成する為のフィルタ。

=head2 フィルタ一覧


=over 4

=item L<Tripletail::InputFilter::HTML>

QUERY_STRING / stdinからリクエストを読む。
L<セッション|Tripletail::Session> は L<クッキー|Tripletail::Cookie> から読む。(デフォルト)

=item L<Tripletail::InputFilter::MobileHTML>

QUERY_STRING / stdinからリクエストを読む。
L<セッション|Tripletail::Session> はFormから読む。文字コード変換には常にUniJPを使う。

=item L<Tripletail::InputFilter::SEO>

SEO入力フィルタ。

=item L<Tripletail::InputFilter::Plain>

何もしないフィルタ。
	
=back


=head2 METHODS

=over 4

=item C<< $TL->newInputFilter >>

  $filter = $TL->newInputFilter

Tripletail::InputFilter オブジェクトを作成。

=item C<< decodeCgi >>

  $filter->decodeCgi($form);

任意の場所からリクエストデータを読み、それを$formに追加する。

=item C<< decodeURL >>

  $filter->decodeURL($form, $url, $fragment)

指定されたURLから(可能なら)読めるデータを読み、それを$formに追加する。
URLにフラグメント部分は含まれない。もしフラグメントが存在したなら、
それは$fragmentに入る。フラグメントが無ければ$fragmentはundefになる。

=back

=head2 Ini パラメータ

=over 4

=item C<< charset >>

    charset = UTF-8

クエリの文字コードを指定する。ここで文字コードを指定した場合は文字コードの自動判別は行われない。
L<< $TL->charconv|Tripletail/"charconv" >>で使用できる文字コードを指定可能。

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Filter>

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
