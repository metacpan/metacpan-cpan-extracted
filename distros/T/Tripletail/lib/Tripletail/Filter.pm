# -----------------------------------------------------------------------------
# Tripletail::Filter - CGI出力加工
# -----------------------------------------------------------------------------
package Tripletail::Filter;
use strict;
use warnings;
use Tripletail;

1;

sub _new {
	my $class = shift;
	my $this = bless {} => $class;

	# 既にヘッダを出力したかどうか
	$this->{header_flushed} = undef;

	# 置換するヘッダ(setHeaderで設定されたもの)
	$this->{replacement} = {}; # {キー => 値}

	# 追加するヘッダ(addHeaderで設定されたもの)
	$this->{addition} = {}; # {キー => [値, ...]}

	$this->{option} = { @_ };

	$this;
}

sub setHeader {
	my $this = shift;
	my $key = shift;
	my $value = shift;

	if(!defined($key)) {
		die __PACKAGE__."#setHeader: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#setHeader: arg[1] is a reference. [$key] (第1引数がリファレンスです)\n";
	}

	if(!defined($value)) {
		die __PACKAGE__."#setHeader: arg[2] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($value)) {
		die __PACKAGE__."#setHeader: arg[2] is a reference. [$value] (第1引数がリファレンスです)\n";
	}

	$this->{replacement}{$key} = $value;
	$this;
}

sub addHeader {
	my $this = shift;
	my $key = shift;
	my $value = shift;

	if(!defined($key)) {
		die __PACKAGE__."#addHeader: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#addHeader: arg[1] is a reference. [$key] (第1引数がリファレンスです)\n";
	}

	if(!defined($value)) {
		die __PACKAGE__."#addHeader: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($value)) {
		die __PACKAGE__."#addHeader: arg[2] is a reference. [$value] (第2引数がリファレンスです)\n";
	}

	my $old = $this->{addition}{$key};
	if($old) {
		push @$old, $value;
	} else {
		$this->{addition}{$key} = [$value];
	}

	$this;
}

sub print {
	# デフォルトの実装。必要に応じてオーバーライドする。
	my $this = shift;
	my $data = shift;

	if(ref($data)) {
		die __PACKAGE__."#print: arg[1] is a reference. [$data] (第1引数がリファレンスです)\n";
	}

	my $output = $this->_flush_header;
	$output .= $data;

	$output;
}

sub flush {
	# デフォルトの実装。必要に応じてオーバーライドする。
	my $this = shift;

	my $data = $this->_flush_header;

	$data;
}

sub _make_header {
	# フィルタが独自のヘッダを追加する場合は
	# このメソッドをオーバーライドする。

	# 戻り値: {ヘッダ名 => 値}
	#         または {ヘッダ名 => [値1, 値2, ...]}
	return {};
}

sub _flush_header {
	my $this = shift;
	if($this->{header_flushed}) {
		# 既にヘッダは出力済み。
		return '';
	}

	my $header = $this->_make_header;

	# 置換
	while(my ($key, $val) = each %{$this->{replacement}}) {
		$header->{$key} = $val;
	}

	# 追加
	while(my ($key, $val) = each %{$this->{addition}}) {
		my $oldval = $header->{$key};
		if(!defined($oldval)) {
			$header->{$key} = $val;
		} elsif(ref($oldval) eq 'ARRAY') {
			push @$oldval, @$val;
		} else {
			$header->{$key} = [$oldval, @$val];
		}
	}

	my $output;
	if( $TL->{mod_perl} )
	{
		my $r = $TL->{mod_perl}{request};
		$r->content_type(delete $header->{'Content-Type'});
		if( exists($header->{'Location'}) )
		{
			$r->status(302); # 302 Found.
		}
		my $headers_out = $r->headers_out;
		while(my ($key, $val) = each %$header) {
			if(ref($val) eq 'ARRAY') {
				foreach(@$val) {
					$headers_out->add($key, $_);
				}
			} else {
				$headers_out->set($key, $val);
			}
		}
		$output = '';
	}else
	{
		# 文字列化
		while(my ($key, $val) = each %$header) {
			if(ref($val) eq 'ARRAY') {
				foreach(@$val) {
					$output .= sprintf "%s: %s\r\n", $key, $_;
				}
			} else {
				$output .= sprintf "%s: %s\r\n", $key, $val;
			}
		}
		$output .= "\r\n";
	}

	$this->{header_flushed} = 1;
	$output;
}

sub _fill_option_defaults {
	my $this = shift;
	my $defaults = shift;

	foreach(@$defaults) {
		my ($key, $val) = @$_;
		if(exists($this->{option}{$key})) {
			next;
		}

		$this->{option}{$key} = do {
			if(ref($val) eq 'CODE') {
				$val->();
			} else {
				$val;
			}
		};
	}

	$this;
}

sub _check_options {
	my $this = shift;
	my $check = shift;

	foreach my $key (keys %$check) {
		if(!(exists $this->{option}{$key})) {
			# 未定義だった
			$this->{option}{$key} = undef;
		}
	}

	while(my ($key, $val) = each %{$this->{option}}) {
		my $list = $check->{$key};
		if(!defined($list)) {
			# このオプションは許されていない。
			die "TL#setContentFilter: ".ref($this)." does not accept option [$key]. (${key}は使用できないオプションです)\n";
		}

		foreach(@$list) {
			if($_ eq 'defined') {
				if(!defined($val)) {
					die "TL#setContentFilter: ".ref($this).": option [$key] has to be defined. (${key}オプションが指定されていません)\n";
				}
			} elsif($_ eq 'no_empty') {
				if(defined($val) && !ref($val) && $val eq '') {
					die "TL#setContentFilter: ".ref($this).": option [$key] has to be not empty. (${key}オプションが空です)\n";
				}
			} elsif($_ eq 'scalar') {
				if(defined($val) && ref($val)) {
					die "TL#setContentFilter: ".ref($this).": option [$key] has to be not a reference. [$val] (${key}オプションがリファレンスです)\n";
				}
			} elsif($_ eq 'array') {
				if(defined($val) && ref($val) ne 'ARRAY') {
					die "TL#setContentFilter: ".ref($this).": option [$key] has to be an ARRAY Ref. [$val] (${key}オプションが配列のリファレンスではありません)\n";
				}
			} else {
				die "TL#setContentFilter: ".ref($this).": internal error; unknown check type [$_]. (内部エラー:${key}オプションのチェック方法が不明です)\n";
			}
		}
	}

	$this;
}

sub reset {
	# デフォルトの実装。必要に応じてオーバーライドする。
	my $this = shift;

	$this->{header_flushed} = undef;
	%{$this->{replacement}} = ();
	%{$this->{addition}} = ();

	$this;
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::Filter - CGI出力加工

=head1 SYNOPSIS

  $TL->setContentFilter('Tripletail::Filter::HTML', charset => 'UTF-8');
  
  $TL->print("foo\n");

=head1 DESCRIPTION

L<< $TL->print|Tripletail/"print" >> 、 L<< $template->flush|Tripletail::Template/"flush" >>
で出力されるデータを加工するクラス。

L<< $TL->print|Tripletail/"print" >> 、 L<< $template->flush|Tripletail::Template/"flush" >>
によるコードからの出力は、 L<< $TL->setContentFilter|Tripletail/"setContentFilter" >>
によって指定されたフィルタにより加工されてから出力される。


=head2 フィルタ一覧

=over 4

=item L<Tripletail::Filter::HTML> - PC向けHTML出力 (デフォルト)

=item L<Tripletail::Filter::MobileHTML> - 携帯電話向けHTML出力

=item L<Tripletail::Filter::CSV> - CSV出力

=item L<Tripletail::Filter::TEXT> - TEXT出力

=item L<Tripletail::Filter::Binary> - バイナリ出力

=item L<Tripletail::Filter::SEO> - SEO出力フィルタ

=back


=head2 METHODS

=over 4

=item C<< _new >>

  $filter = $TL->newFilter(%filteroption)

Tripletail::Filter オブジェクトを作成。
フィルタの初期化を行う。

=item C<< addHeader >>

各フィルターの動作による。

=item C<< setHeader >>

各フィルターの動作による。

=item C<< print >>

  $content = $filter->print($content)

出力すべき内容を受け取り、必要ならデータを加工し、出力すべき内容を返す。

=item C<< flush >>

  $content = $filter->flush

全ての出力内容を出力し終えたときに呼び出される。フィルタ側でバッファしている
内容があれば、その内容を返す。内容がなければ空文字列を返す。

但し、エラー時には呼び出されないこともある。

(0.44 以降、再初期化処理は L</reset> メソッドに分離)

=item C<< reset >>

  $content = $filter->reset

リクエスト処理の終了時に呼び出される。

FCGI使用時には、フィルタオブジェクトは各リクエストの間で使い回される為、
このメソッドで必ず内部状態を初期化する必要がある。

(0.44 以降, 0.43 までは L</flush> の一部でした。)

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::InputFilter>

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
