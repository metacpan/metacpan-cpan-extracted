# -----------------------------------------------------------------------------
# Tripletail::HtmlMail - 指定されたURLからデータを取得し、HTMLメールを作成する
# -----------------------------------------------------------------------------
package Tripletail::HtmlMail;
use strict;
use warnings;
use LWP::UserAgent;
use MIME::QuotedPrint;
use Tripletail;
use Unicode::Japanese ();
my $CID_COUNT = 0;

1;

sub _new {
	my $pkg = shift;
	my $this = {};

	bless $this, $pkg;

	$this->init;

	$this;
}

sub init {
	my $this = shift;

	$this->{error} = '';
	$this->{header} = {};
	$this->{html} = undef;
	$this->{text} = undef;
	$this->{enclose} = 0;
	$this->{linkAbs} = 1;
	$this->{url2cid} = {};
	$this->{url2name} = {};
	$this->{cid2url} = {};
	$this->{timeout} = 60;
	$this->{eventListener} = undef;
	$this->{Preprocessor} = \&_deleteNullPreprocessor;

	$this;
}

sub setProxy {
	my $this = shift;
	my $proxy = shift;

	$this->{proxy} = $proxy;

	$this;
}

sub setEventListener {
	my $this = shift;
	my $sub = shift;

	$this->{eventListener} = $sub;

	$this;
}

sub setPreprocessor {
	my $this = shift;
	my $sub = shift;

	$this->{Preprocessor} = $sub;

	$this;
}

sub setTimeout {
	my $this = shift;
	my $timeout = shift;

	$this->{timeout} = $timeout;

	$this;
}

sub _deleteNullPreprocessor {
	my $ctype = shift;
	my $data = shift;

	if($ctype =~ m,^text/,i) {
		$data =~ tr/\0//d;
	}

	$data;
}

sub _event {
	my $this = shift;
	my $message = shift;

	if(defined($this->{eventListener})) {
		$this->{eventListener}->($message);
	}

	$this;
}

sub setTextURL {
	my $this = shift;
	my $url = shift;

	$this->{text} = $url;

	$this;
}

sub setHtmlURL {
	my $this = shift;
	my $url = shift;

	$this->{html} = $url;

	$this;
}

sub setEnclose {
	my $this = shift;
	my $enclose = shift; # 0:絶対URL変換のみ 1:ファイル埋め込み

	$this->{enclose} = $enclose;

	$this;
}

sub setLinkAbs {
	my $this = shift;
	my $linkabs = shift; # 0:リンク変換無し 1:リンク変換有り

	$this->{linkAbs} = $linkabs;

	$this;
}

sub setHeader {
	my $this = shift;
	my $header;

	if(ref($_[0]) eq 'HASH') {
		$header = shift;
	} elsif(!ref($_[0])) {
		$header = { @_ };
	}

	foreach my $key (keys %$header) {
		$this->{header}{$key} = $header->{$key};
	}

	$this;
}

sub makeMail {
	my $this = shift;

	my $mail = eval {
		$this->_makeMail;
	};
	if($@) {
		$this->{error} = $@;

		undef;
	} else {
		$mail;
	}
}

sub _makeMail {
	my $this = shift;

	my $is_single = 0;
	if(!defined($this->{text}) && !$this->{enclose}) {
		$is_single = 1;
	}

	my $mail = $TL->newMail->setHeader($this->{header});
	my $inmail = $TL->newMail;

	if(!$is_single) {
		$mail->setHeader(
			'Content-Type' => 'multipart/related; type="multipart/alternative"',
			'Content-Transfer-Encoding' => '7bit',
		);

		$inmail->setHeader('Content-Type' => 'multipart/alternative');

		if(defined($this->{text})) {
			$this->_event("URL: $this->{text}<br>\n");
			$this->_event("テキストファイルを取得中です．．．\n");
			my $res = $this->_getHTTP($this->{text});
			$this->_event("完了しました．\n");

			my $type = $res->header('Content-Type');
			$type =~ s!text/html,\s*(text/html)!$1!;
			my $size = length($res->content);
			$this->_event("(タイプ:$type)(サイズ:$size)\n");
			$this->_event("<br>\n");

			if($type !~ m,^text/plain,) {
				die 'テキストメールの原稿が，テキスト形式ではありません．';
			}

			my $text = $res->content;
			if(defined($this->{Preprocessor})) {
				$text = $this->{Preprocessor}->($type, $text, $res);
			}
			$text = Unicode::Japanese->new($text, 'auto')->get;

			$inmail->attach(
				type     => 'text/plain',
				encoding => '7bit',
				data     => $text,
			);
		}
	}

	$this->_event("URL: $this->{html}<br>\n");
	$this->_event("HTMLファイルを取得中です．．．\n");
	my $res = $this->_getHTTP($this->{html});
	$this->_event("完了しました．\n");

	my $type = $res->header('Content-Type');
	$type =~ s!text/html,\s*(text/html)!$1!;
	my $size = length($res->content);
	$this->_event("(タイプ:$type)(サイズ:$size)\n");
	$this->_event("<br>\n");

	if($type !~ m,^text/html,) {
		die 'HTMLメールの原稿が，HTML形式ではありません．';
	}

	my $encloseURL = {};
	my $html = $res->content;
	if(defined($this->{Preprocessor})) {
		$html = $this->{Preprocessor}->($type, $html, $res);
	}

	my $outhtml = $html;
	if($this->{linkAbs}) {
		my $unijp = Unicode::Japanese->new;
		my $code = $unijp->getcode($outhtml);
		if(($code ne 'ascii') && ($code ne 'binary') && ($code ne 'unknown')) {
			$outhtml = $unijp->set($outhtml, $code)->get;
		}

		$outhtml = $this->_absLink($encloseURL, $res->base, $outhtml);

		if(($code ne 'ascii') && ($code ne 'binary') && ($code ne 'unknown')) {
			$outhtml = $unijp->set($outhtml)->conv($code);
		}
	}

	# \0に囲まれた部分のエンコードを避ける特殊なQPエンコードをするかどうか
	my $usemyqp = 0;

	if($is_single) {
		if($outhtml =~ m/\0/) {
			# 特殊なQP
			$usemyqp = 1;

			$mail->setHeader(
				'Content-Type'              => $type,
				'Content-Transfer-Encoding' => 'X-quoted-printable',
			);
			$mail->_setBody(
				$this->_encodeMail($outhtml),
			);
		} elsif($outhtml =~ m/[\x80-\xff]/) {
			# 8bit目が使われているのでBase64
			$mail->setHeader(
				'Content-Type'              => $type,
				'Content-Transfer-Encoding' => 'base64',
			);
			$mail->_setBody($outhtml);
		} else {
			# 通常のQP
			$mail->setHeader(
				'Content-Type'              => $type,
				'Content-Transfer-Encoding' => 'quoted-printable',
			);
			$mail->_setBody($outhtml);
		}
	} else {
		if($outhtml =~ m/\0/) {
			# 特殊なQP
			$usemyqp = 1;

			my $part = $TL->newMail;
			$part->setHeader(
				'Content-Type'              => $type,
				'Content-Transfer-Encoding' => 'X-quoted-printable',
			);
			$part->_setBody(
				$this->_encodeMail($outhtml),
			);

			$inmail->attach(
				part => $part,
			);
		} elsif($outhtml =~ m/[\x80-\xff]/) {
			# 8bit目が使われているのでBase64

			my $part = $TL->newMail;
			$part->setHeader(
				'Content-Type'              => $type,
				'Content-Transfer-Encoding' => 'base64',
			);
			$part->_setBody($outhtml);

			$inmail->attach(
				part => $part,
			);
		} else {
			# 通常のQP

			my $part = $TL->newMail;
			$part->setHeader(
				'Content-Type'              => $type,
				'Content-Transfer-Encoding' => 'quoted-printable',
			);
			$part->_setBody($outhtml);

			$inmail->attach(
				part => $part,
			);
		}

		$mail->attach(part => $inmail);

		if($this->{enclose}) {
			$this->_event("関連ファイルをダウンロードします．<br>\n");

			my $enclosedURL;

			while(1) {
				foreach my $url (keys %$encloseURL) {
					next if($enclosedURL->{$url});

					$this->_event("URL: $url<br>\n");
					$this->_event("関連ファイルを取得中です．．．\n");

					$enclosedURL->{$url}++;

					my $attach = $this->_getHTTP($url);
					$this->_event("完了しました．\n");

					my $type = $attach->header('Content-Type');
					$type =~ s!text/html,\s*(text/html)!$1!;
					my $size = length($attach->content);
					$this->_event("(タイプ:$type)(サイズ:$size)\n");
					$this->_event("<br>\n");

					my $content;
					if($type =~ 'text/html') {
						my $html = $attach->content;
						if(defined($this->{Preprocessor})) {
							$html = $this->{Preprocessor}->($type, $html);
						}

						$content = $html;
						if($this->{linkAbs}) {
							my $unijp = Unicode::Japanese->new;
							my $code = $unijp->getcode($content);

							if(($code ne 'ascii') && ($code ne 'binary') && ($code ne 'unknown')) {
								$content = $unijp->set($content, $code)->get;
							}

							$content = $this->_absLink(
							$encloseURL,
							$attach->base,
							$content);

							if(($code ne 'ascii') && ($code ne 'binary') && ($code ne 'unknown')) {
								$content = $unijp->set($content)->conv($code);
							}
						}
					} elsif($type =~ 'text/css') {
						my $css = $attach->content;
						if(defined($this->{Preprocessor})) {
							$css = $this->{Preprocessor}->($type, $css);
						}

						$content = $css;
						if($this->{linkAbs}) {
							my $unijp = Unicode::Japanese->new;
							my $code = $unijp->getcode($content);

							if(($code ne 'ascii') && ($code ne 'binary') && ($code ne 'unknown')) {
								$content = $unijp->set($content, $code)->get;
							}

							$content = $this->_absLinkCss(
								$encloseURL,
								$attach->base,
								$content
							);

							if(($code ne 'ascii') && ($code ne 'binary') && ($code ne 'unknown')) {
								$content = $unijp->set($content)->conv($code);
							}
						}
					} else {
						$content = $attach->content;
						if(defined($this->{Preprocessor})) {
							$content = $this->{Preprocessor}->($type, $content);
						}
					}

					$type .= '; name="' . $this->{url2name}{$url} . '"';

					if($content =~ m/[\x80-\xff]/) {
						my $part = $TL->newMail;
						$part->setHeader(
							'Content-Type' => $type,
							'Content-ID'   => "<$this->{url2cid}{$url}>",
							'Content-Transfer-Encoding' => 'base64',
						);
						$part->_setBody($content);

						$mail->attach(
							part => $part,
						);
					} else {
						my $part = $TL->newMail;
						$part->setHeader(
							'Content-Type' => $type,
							'Content-ID'   => "<$this->{url2cid}{$url}>",
							'Content-Transfer-Encoding' => '7bit',
						);
						$part->_setBody($content);

						$mail->attach(
							part => $part,
						);
					}
				}

				my $count1 = (keys %$encloseURL);
				my $count2 = (keys %$enclosedURL);

				if($count1 == $count2) {
					last;
				}
			}
		}
	}

	my $mailstr = $mail->toStr;

	if($usemyqp) {
		$mailstr =~ s/^Content-Transfer-Encoding: X-quoted-printable$/Content-Transfer-Encoding: quoted-printable/img;
	}

	$mailstr;
}

sub _encodeMail {
	my $this = shift;
	my $data = shift;

	my $encoded;

	foreach my $block (split(/(\0[^\0]+?\0)/, $data)) {
		if($block =~ m/^\0([^\0]+?)\0$/) {
			$encoded .= $block . "=\n";
		} else {
			$encoded .= encode_qp($block) . "=\n";
		}
	}

	$encoded;
}

sub getError {
	my $this = shift;

	$this->{error};
}

sub _absLink {
	my $this = shift;
	my $encloseURL = shift;
	my $base = shift;
	my $html = shift;

	my $filter = $TL->newHtmlFilter(
		interest => [qr/.+/], # style属性があるので全タグを対象に
		track    => ['style'], # style要素の中であるかどうかを知りたい
		filter_text => 1,
	);
	$filter->set($html);

	while(my ($context, $elem) = $filter->next) {
		if($elem->isText) {
			if($context->in('style')) {
				$elem->str(
					$this->_absLinkCss($encloseURL, $base, $elem->str)
				);
			}
		} elsif($elem->isElement) {
			if(my $style = $elem->attr('style')) {
				$elem->attr(
					style => $this->_absLinkCss($encloseURL, $base, $style)
				);
			}

			foreach my $key (qw(href src background action longdesc lowsrc usemap codebase)) {
				my $link = $elem->attr($key);
				defined $link or next;

				if($link =~ m/^javascript:/ || $link =~ m/^mailto:/ || $link =~ m/^ftp:/) {
					# 弄らない
					next;
				}

				if($link =~ m/^[^\#\0]/) {
					eval {
						if($link !~ m,((?:https?|ftp)://[\x21-\x7e]+),) {
							$link = URI->new($link)->abs($base)->as_string;
						}
						$link =~ s/\%00/\0/g;

						if(lc($elem->name) ne 'a' && lc($elem->name) ne 'form') {
							$encloseURL->{$link}++;
						}
					};
				}

				if($this->{enclose} && lc($elem->name) ne 'a' and lc($elem->name) ne 'form' && $link =~ m/^[^\#\0]/) {
					$link = "cid:" . $this->_getCID($link);
				}

				$elem->attr($key => $link);
			}
		}
	}

	$filter->toStr;
}

sub _getCID {
	my $this = shift;
	my $link = shift;

	my $cid;
	if(exists($this->{url2cid}{$link})) {
		$cid = $this->{url2cid}{$link};
	} else {
		$cid = sprintf('%d$%d$%d$tmmlib7cid@%s', $CID_COUNT, time, $$,
			$TL->newMail->_getHostname);
		$this->{url2cid}{$link} = $cid;
		$this->{cid2url}{$cid} = $link;
		my $name = $link;
		$name =~ s,.*?([^\.]+)$,$1,;
		$name =~ s,\?.*,,;
		$name =~ s,\#.*,,;

		$this->{url2name}{$link} = $CID_COUNT . '.' . $name;
		$CID_COUNT++;
	}

	$cid;
}

sub _absLinkCss {
	my $this = shift;
	my $encloseURL = shift;
	my $base = shift;
	my $css = shift;

	my $outcss;

	foreach (split(/(url\((?:[^\)]+)\))/i, $css)) {
		if(m/^url\(([^\)]+)\)/i) {
			my $link = $1;
			eval {
				$link = URI->new($link)->abs($base)->as_string;
				$link =~ s/\%00/\0/g;
			};

			if($this->{enclose}) {
				my $cid = $this->_getCID($link);
				$outcss .= 'url(cid:' . $cid . ')';
			} else {
				$outcss .= 'url(' . $link . ')';
			}
			$encloseURL->{$link}++;
		} else {
			$outcss .= $_;
			next;
		}
	}

	$outcss;
}

sub _getHTTP {
	my $this = shift;
	my $url = shift;

	my $ua = new LWP::UserAgent;
	$ua->timeout($this->{timeout});
	$ua->agent('TripleTail/1.0' . ' ' . $ua->agent);
	if(defined($this->{proxy})) {
		$ua->proxy("http://$this->{proxy}/");
	}

	my $req = new HTTP::Request GET => $url;

	my $res = $ua->request($req);

	my $status = $res->status_line;
	$this->_event("(Status:$status)．．．\n");

	if(!$res->is_success) {
		die "ダウンロードに失敗しました．<br>\nURL: $url<br>Status: $status<br>\n";
	}

	$res;

}


__END__

=encoding utf-8

=head1 NAME

Tripletail::HtmlMail - 指定されたURLからデータを取得し、HTMLメールを作成する。

=head1 SYNOPSIS

  my $mail = $TL->newHtmlMail
      ->setEventListener(\&log_func)
      ->setHeader(
	  From    => 'null@example.org',
	  To      => 'null@example.org',
	  Subject => 'テストメール',
	 )
      ->setTextURL('http://example.org/foo.txt')
      ->setHtmlURL('http://example.org/foo.html')
      ->setEnclose(1)
      ->makeMail;

=head1 DESCRIPTION

HtmlMail クラスでは、名前等のテンプレート展開を行うための
支援機能をサポートしています。
（ここでいうテンプレート機能とは、名前等をメールに埋め込むことで、
Templateクラスの機能とは無関係です）

通常のタグをHTML中に書いてもBase64 エンコードされてしまうため、
そのままではテンプレート展開ができません。
また、1通ずつエンコードし直すのはパフォーマンス上の問題が発生します。

HtmlMail クラスでは、HTMLメール中の m/\0[^\0]+?\0/ にマッチする
文字列を特殊視します。この文字列が存在する場合、文字列の前後で分割し、
それぞれを Base64 エンコードします。

m/\0[^\0]+?\0/ にマッチした文字列はそのまま残るので、後に
その部分に Base64 エンコードした文字列を埋め込むことで、
テンプレート展開を行うことができます。

テンプレート展開支援についての詳しい機能は、setPreprocessor メソッド
のマニュアルを参照してください。

=head2 メーラー対応状況

 項目                                    OutLook2000     OL Express 6    Becky! Ver2     Netscape4.78    Netscape6       YahooMail       HotMail         InfoseekMail
 文字コード：JIS                         ○              ○              ○              ○              ○              ○              ○              ○
 文字コード：SJIS                        ○              ○              ○              ○              ○              ○              ○              ×
 文字コード：EUC                         ○              ○              ○              ○              ○              ○              ○              ○
 文字コード：UTF-8                       ○              ○              ○              ×              ○              ×              ×              ×
 画像埋込                                ○              ○              ○              ○              ○              ×              ○              ×
 画像外部参照                            ○              ○              ○              ○              ○              ○              ○              ○(※2)
 EMBED（FLASH等）IFRAME埋込：外部        ○              ○              ×              ×              ○              ×              ×              ○
 EMBED（FLASH等）IFRAME埋込：埋込        ×              ×              ×              ×              ×              ×              ×              ×
 JavaApplet（IFRAME埋込）                ×              ×              ×              ×              ×              ×              ×              ×
 JavaApplet（IFRAME外部参照）            ○              ○              ×              ×              ○              ×              ×              ○
 リンクをクリックしたときの動作          別window        別window        同一window      別window        別window        別window        別window(※1)   同一flame
 フレームHTML外部参照                    ○              ○              ○              △(※3)         ×              ×              ×              ×
 フレームHTML埋込                        ×              ×              ○              △(※3)         ×              ×              ×              ×
 フレーム内画像埋込                      ×              ×              ×              ○(※3)         ×              ×              ×              ×
 FORM                                    ○(※6)         ○              ○              ○              ○(※7)         ○(※7)         ○(※1)         ○(※2)
 JavaScript：onLoadの動作                ×              △(※8)         ×              △(※9)         ×              ×              ×              ×
 JavaScriptの動作                        ×              △(※8)         ×              △(※9)         △(※9)         ×              ×              ×
 HTML内蔵CSS                             ○              ○              ○              ×(※4)         ○              ○              ×              △（※11）
 HTML内蔵CSS画像埋込                     ○              ○              ○              ×(※4)         ×              ×              ×              ×
 HTML内蔵CSS画像外部参照                 ○              ○              ○              ×(※4)         ○              △(※5)         ×              ×
 外部CSS                                 ○              ○              ○              ×              ○              ×              ×              ○(※2,※5)
 外部CSS画像埋込                         ○              ○              ○              ×              ×              ×              ×              ×
 外部CSS import外部参照                  ○              ○              ○              ×              ○              ×              ×              ○(※2)
 外部CSS import埋込                      ○              ○              ×              ×              ×              ×              ×              ×
 
 Becky! Ver1：HTML対応が非常に限定されているため，本ソフトで作成したHTMLメールは表示できません。
 @nifty：WebメールはHTMLに対応していません。
 
 ※１：上部にＭＳＮのメッセージが出現。
 ※２：対応する文字コードを使用したHTMLのみ可。
 ※３：NOFRAMEタグ内のHTMLを表示。
 ※４：表示が崩れる（ブラウザでは見られる）。
 ※５：背景画像がメール表示枠をはみ出る。
 ※６：フォーム入力の操作性に問題あり（誤操作によりメール削除する危険性アリ）。
 ※７：文字コードが一部崩れる可能性有り。
 ※８：セキュリティ設定が「インターネット」で且つ、インターネットのセキュリティレベルが「中」の時に可。
 ※９：詳細設定にて、「メールとニュースでJavaScriptを使用する」がチェックされていれば可。
 ※10：添付は可能、実行はJavaセキュリティによる可否あり。
 ※11：背景画像の使用は不可能。

2005年1月現在

=head2 METHODS

=over 4

=item $TL->newHtmlMail

  $htmlmail = $TL->newHtmlMail

Tripletail::HtmlMail オブジェクトを作成。

=item init

  $htmlmail->init

メールオブジェクトを初期化します。
インスタンスの create 直後と同じ状態になります。

=item setProxy

  $htmlmail->setProxy($PROXY)

$PROXY : 使用するプロキシ "host:port" 形式。

undef を指定するとダイレクト接続になります。

=item setEventListener

  $htmlmail->setEventListener(\&FUNC)

イベントリスナーを設定します。
HTML取得等のイベントに従って、リスナー関数が呼び出され、
第１引数にメッセージが渡されます。

メッセージはHTML形式で返されます。

=item setPreprocessor

プリプロセッサを指定します。
HtmlMailクラスは、データを受信すると、各種加工処理の前に
プリプロセッサ関数を呼び出します。

デフォルトでは、NULL 文字をカットする関数が設定されます。
（これはテンプレート展開支援機能の誤動作を防ぐためです）

プリプロセッサ関数は、第１引数に Content-Type、第２引数に
データ内容を受け取り、データを返します。

このとき、タグとして扱いたい部分を、m/\0[^\0]+?\0/ に
マッチする文字列に置き換えます。

デフォルトで設定される関数は下記のコードです。

 sub _deleteNullPreprocessor {
   my $ctype = shift;
   my $data = shift;
 
   if($ctype =~ m,^text/,i)
     {
       $data =~ tr/\0//d;
     }
 
   $data;
 }

HTML・テキスト・画像等、全てのコンテンツタイプのデータで
呼び出されるため、必ず第１引数の内容を確認して動作を
振り分けてください。

テキストは、メール生成時に自動的にJISに変換されますが、
その他のコンテンツはコード変換されません。

埋め込むときに漢字コードを判別する必要があるので、
HTMLメールの場合は、後の展開処理用に漢字コードをタグの中に
埋め込んでおく必要があります。

=item setTimeout

  $htmlmail->setTimeout($SEC)

外部サーバーからデータを取得するときのタイムアウト秒数を
設定します。

setTimeoutメソッドを使用しなかった場合は、デフォルト値として
60 秒が設定されます。

=item setTextURL

  $htmlmail->setTextURL($URL)

テキストドキュメントを取得するURLを指定します。

Content-Type は強制的に text/plain とされます。
URL におかれたコンテンツが正しい Content-Type で
あるかどうかはチェックされません。

=item setHtmlURL

  $htmlmail->setHtmlURL($URL)

HTMLドキュメントを取得するURLを指定します。

URL におかれたコンテンツが正しい Content-Type で
あるかどうかはチェックされません。

=item setEnclose

  $htmlmail->setEnclose($FLAG)

関連ファイルをメールに埋め込むかどうか指定します。
埋め込みは、ブラウザによって正しく表示できないことがあります。

0の場合、関連ファイルは埋め込まず、絶対URLに変換する。
1の場合、関連ファイルを埋め込み、CID(Content-ID)に変換する。

デフォルトは0。

=item setLinkAbs

  $htmlmail->setLinkAbs($FLAG)

HTML/CSS中のリンクを絶対URLに加工するかどうかを選択します。
加工しない場合、元のHTMLのリンクが全て絶対URLになっている
必要があります。

加工する場合、HTMLは再パースされるため、
JavaScript や、不正なタグが入っている場合に正しく
再構成されない場合があります。

0の場合、HTML/CSSへの加工を行わない。
1の場合、HTML/CSS中のリンクを絶対URLに加工する。

デフォルトは1。

=item setHeader

  $htmlmail->setHeader(%HEADER)

メールのヘッダを指定します。

=item makeMail

  $MAIL = $htmlmail->makeMail

メール文書を生成します。

生成中に発生したイベントは、setEventListener でリスナーが
設定されていれば、そこに送られます。

メール文書生成中にエラーが発生するとundef が返り、
getError でエラーメッセージが取得できるようになります。

=item getError

  $ERROR = $htmlmail->getError

発生したエラー内容を取得します。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Mail>

=item L<Tripletail::Sendmail>

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
