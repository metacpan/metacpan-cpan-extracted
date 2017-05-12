# -----------------------------------------------------------------------------
# Tripletail::Filter::MobileHTML - 携帯電話向けHTML出力用フィルタ
# -----------------------------------------------------------------------------
package Tripletail::Filter::MobileHTML;
use strict;
use warnings;
use Tripletail;
use Unicode::Japanese ();
use base 'Tripletail::Filter::HTML';

# Tripletail::Filter::MobileHTMLは、
# * 文字コードの変換をする
# * フォームへ"CCC=愛"を追加する
# * 外部リンクの書換えを *する*
# * セッションデータをリンク・フォームに追加 *する*
# * Content-Dispositionを出力しない

# オプション一覧:
# * charset     => 出力の文字コード。(UTF-8から変換される)
#                  常にUniJPを用いて変換される。
# * contenttype => デフォルト: text/html; charset=(CHARSET)

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);
	
	$TL->{outputbuffering} = 1;
	
	$this;
}

sub _setCode {
	my $this = shift;

	do{
		my $set_ctype = $this->{replacement}{'Content-Type'};
		my $add_ctype = $this->{addition}{'Content-Type'} || [];
		my $ctype = $set_ctype ? $set_ctype : ($add_ctype->[0] || '');
		if( $ctype && $ctype =~ /hdml/i )
		{
			return;
		}
	};

	my $ocode = 'sjis';
	if(my $agent = $ENV{HTTP_USER_AGENT}) {
		if($agent =~ m/^DoCoMo/i) {
			$ocode = 'sjis-imode';
		} elsif($agent =~ m/^ASTEL/i) {
			$ocode = 'sjis-doti';
		} elsif($agent =~ m/^(Vodafone|SoftBank|MOT-)/i) {
			$ocode = 'utf8-jsky';
		} elsif($agent =~ m/^(J-PHONE)/i) {
			$ocode = 'sjis-jsky';
		} elsif($agent =~ m/UP\.Browser/i) {
			# Softbank端末かつUP.Browserを含むものもあるのでSoftbankの後に判別すること
			$ocode = 'sjis-au';
		}
	}
	
	my $ctype = $this->{option}{type} eq 'html' ? 'text/html' : 'application/xhtml+xml';
	
	$this->{option}{charset} = $ocode;
	if($ocode =~ m/^sjis/) {
		$this->{option}{contenttype} = "$ctype; charset=Shift_JIS";
	} elsif($ocode =~ m/^utf8/) {
		$this->{option}{contenttype} = "$ctype; charset=UTF-8";
	} else {
		die "internal errlr.\n";
	}
	
	$this->setHeader('Content-Type' => $this->{option}{contenttype});
	
	$this;
}

sub print {
	my $this = shift;
	my $data = shift;

	if(!$this->{content_printed}) {
		# content_printed は Tripletail::Filter::HTML の属性.
		
		$this->_setCode;
		
		if(defined(&Tripletail::Session::_getInstance)) {
			# Tripletail::Sessionが有効になっているので、データが有れば、それを$this->{save}に加える。
			foreach my $group (Tripletail::Session->_getInstanceGroups) {
				Tripletail::Session->_getInstance($group)->_setSessionDataToForm($this->{save});
			}
		}
	}

	$this->SUPER::print($data);
}

sub _make_header {
	my $this = shift;
	
	# クッキーの出力は行わない
	
	my %opts = ();
	if(defined $this->{locationurl}) {
		if(!$TL->getDebug->{location_debug}) {
			# relinkした上でLocationを生成。
			%opts = (Location => $this->_relink(url => $this->{locationurl}));
		}
	}
	
	return {
		%opts,
	};
}

__END__

=encoding utf-8

=for stopwords
	ASTEL
	AU
	CGI
	DoCoMo
	HDML
	Softbank
	TripletaiL
	UTF
	UTF-8
	Vodafone
	Willcom
	XHTML
	YMIRLINK
	addHeader
	contenttype
	getSaveForm
	http
	https
	setHeader
	toExtLink
	toLink


=head1 NAME

Tripletail::Filter::MobileHTML - 携帯電話向け HTML 出力用フィルタ

=head1 SYNOPSIS

  $TL->setContentFilter('Tripletail::Filter::MobileHTML');
  
  $TL->print($TL->readTextFile('foo.html'));

=head1 DESCRIPTION

HTML に対して以下の処理を行う。

=over 4

=item *

絵文字対応の漢字コード変換

=item *

HTTPヘッダの管理。TLのIni設定のoutputbufferingを強制的に1にセットし、Content-Lengthヘッダを出力させる。（携帯では必須）

=item *

E<lt>form action=""E<gt> が空欄の場合、自分自身の CGI 名を埋める

=item *

特定フォームデータを指定された種別のリンクに付与する

=back

L<Tripletail::Filter::HTML> との違いは以下の通り。

=over 4

=item *

セッション用のデータを全てのリンクに追記し、クッキーでの出力はしない。

=back

=head2 セッション

携帯端末ではクッキーが利用できない場合があるため、セッション情報を
クッキーではなくフォームデータとして引き渡す必要がある。

TripletaiL では、L<Tripletail::Filter::MobileHTML> フィルタを使うことで
この作業を半自動化することができる。

L<Tripletail::Filter::MobileHTML> フィルタは、出力時にリンクやフォームを
チェックし、セッション情報を付与すべきリンク・フォームであれば、
自動的にパラメータを追加する。

セッション情報を付与すべきかどうかは、以下のように判断する。

=over 4

=item *

リンクの場合は、リンクの中に C<INT> というキーが存在すれば、セッション情報を
付与し、 C<INT> キーを削除する。
C<INT> キーがなければ、セッション情報は付与されない。

 <a href="tl.cgi?INT=1">セッション情報が付与されるリンク</a>
 <a href="tl.cgi">セッション情報が付与されないリンク</a>

C<INT> キーは、Form クラスの toLink メソッドを利用すると自動的に付与される。
toExtLink メソッドを利用すると、C<INT> キーは付与されない。

 <a href="<&LINKINT>">セッション情報が付与されるリンク</a>
 <a href="<&LINKEXT>">セッション情報が付与されないリンク</a>
 
 $template->expand({
   LINKINT => $TL->newForm({ KEY => 'data' })->toLink,
   LINKEXT => $TL->newForm({ KEY => 'data' })->toExtLink,
 });

=item *

フォームの場合は、基本的にセッション情報を付与する。

セッション情報を付与したくない場合は、L<Tripletail::Template/extForm> を使用するか、
フォームタグを以下のように記述する。

 <form action="" EXT="1">

L<Tripletail::Template/extForm> を使用すると、C<EXT="1"> が付与される。

C<EXT="1"> が付与されているフォームに関しては、セッション情報の付与を行わない。
また、C<EXT="1"> は出力時には削除される。

=back

セッション情報は、 http 領域用のセッション情報は C<"SID + セッショングループ名">、
https 領域用のセッション情報は C<"SIDS + セッショングループ名"> という名称で保存する。

=head2 絵文字変換

USER_AGENT 文字列を元に、 DoCoMo 、 Softbank （ Vodafone 、 J-PHONE ）、
AU 、 ASTEL を自動判別し、
それぞれの端末用に出力します。
文字コードは Softbank 3G 以外は Shift_JIS ＋ 各キャリアの絵文字コード、
Softbank 3G の場合は UTF-8 ＋ Softbank 絵文字コードとなります。

それ以外の端末（ Willcom や PC ）の場合は、Shift_JIS コードで出力します。

携帯から送信されたフォームデータは、 DoCoMo 、 Softbank 2G 以前（ J-PHONE ）、 AU 、 ASTEL の場合は
Shift_JIS ＋ 各キャリアの絵文字コード、 Softbank 3G の場合は UTF-8 ＋ Softbank 絵文字コードとして
解析します。

それ以外の端末（ Willcom や PC ）の場合は、L<Tripletail::InputFilter::HTML> と同様に
C<CCC> による文字コード判別を行います。


絵文字は、入力時に UTF-8 のプライベート領域にマップされ、出力時に絵文字に戻されます。

入力時と出力時で携帯キャリアが異なる場合は、Unicode::Japanese の絵文字変換マップに
従って変換され、出力されます。

この変換マップは、携帯キャリアが公式に提供している絵文字変換マップとは
異なる部分があります。

=head2 フィルタパラメータ

=over 4

=item type

  $TL->setContentFilter('Tripletail::Filter::MobileHTML', type => 'xhtml');

'C<html>' もしくは 'C<xhtml>' を利用可能。省略可能。

フィルタが HTML を書換える際の動作を調整する為のオプション。
XHTML を出力する際に、このパラメータを C<html> のままにした場合、
不正な XHTML が出力される事がある。

C<xhtml>を指定した場合、コンテントタイプは application/xhtml+xml となる.

デフォルトは 'C<html>'。

=item contenttype

  $TL->setContentFilter(
    "Tripletail::Filter::MobileHTML",
    contenttype => 'text/x-hdml; charset=Shift_JIS',
    charset     => 'Shift_JIS',
  );

HDML 使用時に指定.
それ以外の値の場合はフィルタが自動判定した値で上書きされる.

=back

=head2 METHODS

=over 4

=item getSaveForm

  my $SAVE = $TL->getContentFilter->getSaveForm;

出力フィルタが所持している保存すべきデータが入った、
L<Form|Tripletail::Form> オブジェクトを返す。

=item setHeader

  $TL->getContentFilter->setHeader($key => $value)

他の出力の前に実行する必要がある。

同じヘッダを既に出力しようとしていれば、そのヘッダの代わりに指定したヘッダを出力する。（上書きされる）

=item addHeader

  $TL->getContentFilter->addHeader($key => $value)

他の出力の前に実行する必要がある。

同じヘッダを既に出力しようとしていれば、そのヘッダに加えて指定したヘッダを出力する。（追加される）

=item print

L<Tripletail::Filter>参照

=item reset

L<Tripletail::Filter>参照

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Filter>

=item L<Tripletail::Filter::HTML>

=item L<Tripletail::Form>

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
