# -----------------------------------------------------------------------------
# Tripletail::InputFilter::HTML - 通常HTML向けCGIクエリ読み取り
# -----------------------------------------------------------------------------
package Tripletail::InputFilter::HTML;
use base 'Tripletail::InputFilter';
use strict;
use warnings;
use File::Path ();
use IO::Scalar ();
use Tripletail;

my $TEMPFILE_COUNTER = 0;

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
		# 少し変則的だが、ここで必要に応じてセッションをクッキーから読み出す。
		foreach my $group (Tripletail::Session->_getInstanceGroups) {
			Tripletail::Session->_getInstance($group)->_getSessionDataFromCookies;
		}
	}

	$this;
}

sub decodeURL {
	my $this = shift;
	my $form = shift;
	my $url = shift; # フラグメントは除去済
	my $fragment = shift;

	if($url =~ m/\?(.+)$/) {
		my $newform = $this->_formFromPairs(
		$this->__pairsFromUrlEncoded($1));

		$form->addForm($newform);
	}

	$this;
}

sub __pairsFromCgiInput {
	# 戻り値: ([[key => value], ...], {key => filename, ...})
	#         但しkey, value共にURLデコードされている事。文字コードは生のまま。
	#         valueはファイルハンドルである場合が有る。
	my $this = shift;

	if(!defined($ENV{REQUEST_METHOD})) {
		return ([], undef);
	}

	if(defined($ENV{CONTENT_TYPE}) && $ENV{CONTENT_TYPE} =~ m|multipart/form-data|) {
		$this->__pairsFromMultipart;
	} else {
		($this->__pairsFromUrlEncoded, {});
	}
}

sub __pairsFromUrlEncoded {
	my $this = shift;
	my $input = shift; # optional

	if(!defined($input)) {
		if($ENV{REQUEST_METHOD} eq 'POST') {
			if(!defined($ENV{CONTENT_LENGTH})) {
				die __PACKAGE__.": Post Error: no Content-Length given by the user agent. (POSTメソッドにもかかわらずContent-Lengthヘッダがありませんでした)";
			}

			my $limit = $TL->parseQuantity(
				$TL->INI->get(TL => 'maxrequestsize', '8Mi'));
			if ($ENV{CONTENT_LENGTH} > $limit) { # ファイルは無い
				$TL->log("Post Error: request size [$ENV{CONTENT_LENGTH}] was too big to accept [limit:$limit].");
				die __PACKAGE__.": Post Error: request size was too big to accept. (リクエストサイズが大きすぎます)";
			}

			my $remaining = $ENV{CONTENT_LENGTH};
			my $chunksize = 16 * 1024;
			$input = '';

			while($remaining) {
				my $size = ($remaining > $chunksize) ? $chunksize : $remaining;
				my $chunk;
				my $read = read STDIN, $chunk, $size;

				if(!defined($read)) {
					die $TL->newError('error', __PACKAGE__.": we got IO error while reading from stdin. [$!] (stdinからの読み込み中にIOエラーが発生しました)\n");
				} elsif($read == 0) {
					die $TL->newError('error', __PACKAGE__.": we got EOF while reading from stdin.".
					  " We read ".length($input)." bytes actually but $remaining bytes remain. ".
					  " (stdinからの読み取り途中でEOFを受信しました。".length($input)."バイト読み取りましたが${remaining}バイトが残っています)\n");
				}

				$input .= $chunk;
				$remaining -= $read;
			}
		} else {
			if(!defined($ENV{QUERY_STRING})) {
				return [];
			}

			$input = $ENV{QUERY_STRING};
		}
	}

	if($input eq '') {
		return [];
	}

	my $pairs = []; 
	foreach(split /[&;]/, $input) {
		my ($key, $value) = split /=/, $_, 2;

		$key = defined $key ? $this->_urlDecodeString($key) : '';
		$value = defined $value ? $this->_urlDecodeString($value) : '';

		push @$pairs, [$key => $value];
	}
	$pairs;
}

sub __pairsFromMultipart {
	my $this = shift;

	local($_);

	if($ENV{REQUEST_METHOD} ne 'POST') {
		return ([], {});
	}

	if(!defined($ENV{CONTENT_LENGTH})) {
		return ([], {});
	}

	my $boundary = do {
		if ($ENV{CONTENT_TYPE} =~ m/boundary="([^"]+)"/i or
			  $ENV{CONTENT_TYPE} =~ m/boundary=(\S+)/i) {
			'--' . $1;
		}
		else {
			die __PACKAGE__."#__pairsFromMultipart, we found no boundaries ".
				"in the Content-Type. [$ENV{CONTENT_TYPE}]\n";
		}
	};

	if(($ENV{'HTTP_USER_AGENT'} || '') =~ m/MSIE\s+3\.0[12];\s*Mac|DreamPassport/) {
		# IE3 on Mac のバグ対応
		$boundary =~ s/^--//;
	}

	my $req_limit = $TL->parseQuantity(
		$TL->INI->get(TL => 'maxrequestsize', '8Mi'));

	my $file_limit = $TL->parseQuantity(
		$TL->INI->get(TL => 'maxfilesize', '8Mi'));

	my $chunksize = 16 * 1024;
	if( $req_limit < $chunksize )
	{
		$chunksize = $req_limit;
		
		my $boundary = ( length($boundary)+2 )*2; # +2="\r\n";
		if( $req_limit < $boundary )
		{
			$chunksize = $boundary;
		}
	}

	my $buffer = '';
	my $eof = undef;
	my $non_file_count = 0;
	my $file_count = 0;
	my $pairs = [];
	my $filename_h = {};

	my $current_key = undef;
	my $current_value = undef;

	my $find = sub {
		my $substr = shift;
		index $buffer, $substr, 0;
	};

	my $rest_len = $ENV{CONTENT_LENGTH};
	my $fill = sub {
		# 一度EOFを検出した後に再びfillしようとしたらdie
		if ($eof) {
			die __PACKAGE__.": we got EOF while reading from stdin. (stdinからの読み取り途中でEOFを受信しました)\n";
		}

		# バッファのサイズが maxrequestsize を越えないようにする。
		my $size = $chunksize - length($buffer);
		if ($size == 0) {
			die __PACKAGE__.": read buffer has been full. (読み込みバッファがあふれました。maxrequestsizeが小さすぎるか、リクエストが大きすぎます)\n";
		}
		if( $size > $rest_len )
		{
			$size = $rest_len;
			if ($size <= 0)
			{
				die __PACKAGE__.": already read CONTENT_LENGTH bytes ($ENV{CONTENT_LENGTH}). (Content-Lengthバイトを読み取りましたがデータが残っています)\n";
			}
		}
		
		my $chunk;
		my $read = read STDIN, $chunk, $size;

		if (not defined $read) {
			die __PACKAGE__.": we got IO error while reading from stdin. [$!] (stdinからの読み込み中にIOエラーが発生しました)\n";
		}
		elsif ($read == 0) {
			$eof = 1;
		}
		else {
			$buffer .= $chunk;
			$rest_len -= length($chunk);
		}
	};

	my $fill_until = sub {
		my $str = shift;

		# バッファ中に$strが現れるまでfillし続ける。
		while (index($buffer, $str) == -1) {
			$fill->();
		}
	};

	my $remove_until = sub {
		my $substr = shift;

		my $pos = index $buffer, $substr, 0;
		if ($pos == -1) {
			undef;
		}
		else {
			substr $buffer, 0, $pos, '';
		}
	};

	my $remove = sub {
		my $len = shift;

		substr $buffer, 0, $len, '';
	};

	my $next_header_line = sub {
		# ヘッダを一行読んで返す。ヘッダは改行されている可能性があるが、
		# 改行は空白1つに置き換える。

		while (1) {
			$fill_until->("\x0d\x0a");

			my $pos = index $buffer, "\x0d\x0a";
			if ( $pos>0 && $buffer =~ s/^(.{$pos})\x0d\x0a[ \t]+/$1 /s) {
				next; # もう一度。
			}
			last;
		}

		$buffer =~ s/^(.*?)\x0d\x0a//
		  or die __PACKAGE__."#__pairsFromMultipart: Internal Error (内部エラー)\n";

		$1;
	};

	my $tempdir = $TL->INI->get(TL => tempdir => undef);
	if( defined($tempdir) )
	{
		# trust TL.tempdir parameter.
		$tempdir = $tempdir=~/^(.*)\z/ && $1 or die "untaint";
	}
	my $new_ih = sub {
		if (defined $tempdir) {
			if (!-d $tempdir) {
				File::Path::mkpath($tempdir);
			}
			
			my $filename = "$tempdir/TL-INPUTFILTER-HTML-$$-$TEMPFILE_COUNTER.tmp";
			$TEMPFILE_COUNTER++;

			open my $fh, '+>', $filename
			  or die __PACKAGE__.": failed to open $filename for writing. [$!] (${filename}に書き込めません)\n";

			unlink $filename
			  or die __PACKAGE__.": failed to unlink $filename. [$!] (${filename}を削除できません)\n";

			$fh;
		}
		else {
			IO::Scalar->new;
		}
	};

	my $prepare = sub {
		my $key = shift;
		my $filename = shift;

		if (defined $current_key) {
			die __PACKAGE__."#__pairsFromMultipart: Internal Error. (内部エラー)\n";
		}

		$current_key = $key;

		if (defined $filename) {
			# これはファイル
			$filename_h->{$key} = $filename;
			$current_value = $new_ih->();
		}
		else {
			# これはファイルでない
			$current_value = '';
		}
	};

	my $commit = sub {
		if (not defined $current_key) {
			die __PACKAGE__."#__pairsFromMultipart: Internal Error. (内部エラー)\n";
		}

		if (ref $current_value) {
			# ファイルの先頭にseekする
			seek $current_value, 0, 0;
		}

		push @$pairs, [$current_key, $current_value];

		undef $current_key;
		undef $current_value;
	};

	my $push = sub {
		my $data = shift;
		
		if (not defined $current_key) {
			die __PACKAGE__."#__pairsFromMultipart: Internal Error. (内部エラー)\n";
		}

		if (ref $current_value) {
			# ファイル
			if (length($data) + $file_count > $file_limit) {
				die __PACKAGE__.": we are getting too large file which exceeds the limit. (ファイルサイズが制限を超えました。maxfilesizeを確認してください)\n";
			}
			print $current_value $data;
			$file_count += length($data);
		}
		else {
			# ファイル以外
			if (length($data) + $non_file_count > $req_limit) {
				die __PACKAGE__.": we are getting too large request which exceeds the limit. (リクエストサイズが大きすぎます。maxrequestsizeを確認してください)\n";
			}
			$current_value .= $data;
			$non_file_count += length($data);
		}
	};

	# 少なくとも(バウンダリの長さ+2)の2倍-1バイトを読んで、バッファサイ
	# ズ-(バウンダリの長さ+2)+1バイトだけバッファを消費して行く。例えば
	# バウンダリが --% だった場合、一度に読み込むバイト数は少なくとも9
	# バイト。
	#
	# |現在buf | 次read  |
	# |.........|...**--%.|  **はCRLF。5バイトだけ消費する
	#
	# |.....**--|%........|  5バイトだけ消費するので、バッファにはCRLF以降が残る
	#
	# |....**--%|.........|  バウンダリが全部見えている
	#
	# |.**--%...|.........|  バウンダリが全部見えている
	#
	# 何れの場合もバウンダリの途中までを切り取ってしまう事が無い。
	
	while (1) {
		if ($find->($boundary) == -1) {
			$fill->();
		}
		
		if (defined $remove_until->($boundary)) {
			# バウンダリ検出。
			# 直後に'--'があったら終了。そうでなければ一行ずつヘッダを読む。
			$remove->(length $boundary);
			$fill_until->("\x0d\x0a");

			if ($find->("--") == 0) {
				last;
			}
			
			$remove_until->("\x0d\x0a"); # バウンダリに付けられた改行を削除
			$remove->(2);

			while (1) {
				my $line = $next_header_line->();
				if (not length $line) {
					# ここでヘッダ終わり
					last;
				}
				elsif ($line =~ m/^Content-Disposition:/i) {
					my $key;
					
					if ($line =~ m/(?!file)name="(.+?)"/i or $line =~ m/(?!file)name=(\S+)/i) {
						$key = $1;
					}
					else {
						die __PACKAGE__.": we got a part with no name. (名前がないパートがありました)\n";
					}

					if ($line =~ m/filename="(.*?)"/i or $line =~ m/filename=(\S+)/i) {
						if (not defined $key) {
							die __PACKAGE__.": we got an isolated filename without name. [$_] (名前がないのにファイル名がありました)\n";
						}

						$prepare->($key, $1);
					}
					else {
						$prepare->($key);
					}
				}
				# それ以外のヘッダは無視。
			}

			# バウンダリが見付かるまで push し続ける。
			while (1) {
				if ($find->("\x0d\x0a$boundary") == -1) {
					$fill->();
				}

				if (defined($_ = $remove_until->("\x0d\x0a$boundary"))) {
					# 見付かった
					$push->($_);
					$commit->();
					
					$remove->(2); # バウンダリ直前のCRLFはここで削除
					# バウンダリ自体はここでは削除しない。
					last;
				}
				else {
					my $consume = length($buffer) - (length($boundary) + 2) + 1;
					if ($consume > 0) {
						$push->($remove->($consume));
					}
				}
			}
		}
		else {
			# 恐らくpreambleがあるので、もう一度ループ回す。
		}
	}

	($pairs, $filename_h);
}

__END__

=encoding utf-8

=for stopwords
	CCC
	TL
	YMIRLINK
	decodeCgi
	decodeURL
	CGI
	Ini
	UTF
	UTF-8

=head1 NAME

Tripletail::InputFilter::HTML - 通常 HTML 向け CGI クエリ読み取り

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

以下の場所からクエリを読み取る。

=over 4

=item C<< $ENV{QUERY_STRING} >>

application/x-www-form-urlencoded を読み取る。

=item C<< STDIN >>

application/x-www-form-urlencoded または multipart/form-data を読み取る。
multipartでファイルがアップロードされた場合は、そのファイル名と
IO ハンドルが L<Form|Tripletail::Form> に格納される。
詳しくは L<Tripletail> の Ini パラメータを参照。

=back

また、 L<Tripletail::Session> が有効になっている場合は、セッションデータを
L<クッキー|Tripletail::Cookie> から読み出す。

クエリの文字コードはINIのL<charset|Tripletail::InputFilter/"charset">が指定されていればそれが使用される。
指定されていない場合は自動判別され、文字コード変換には Encode が優先される。
Encode が利用可能でない場合はUnicode::Japaneseが用いられる。

文字コードの自動判別は、フォームの中の CCC キーに含まれる「愛」という文字列によって行われる。
通常、 TL から出力された HTML には、自動的にこの情報が追加されるが、
外部の静的な HTML や FLASH コンテンツ等からフォームデータを渡す場合は、
追加する必要がある。

例えば、 UTF-8 コードで、name キーに「名前」の文字列を渡す場合は、
CCC=%e6%84%9b&name=%E5%90%8D%E5%89%8D
をフォームデータとして渡す。

=head2 METHODS

=over 4

=item decodeCgi

内部メソッド

=item decodeURL

内部メソッド

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::InputFilter>

=item L<Tripletail::InputFilter::MobileHTML>

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
