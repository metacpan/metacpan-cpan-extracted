# -----------------------------------------------------------------------------
# Tripletail::Filter::SEO - SEO出力フィルタ
# -----------------------------------------------------------------------------
package Tripletail::Filter::SEO;
use strict;
use warnings;
use Tripletail;
use base 'Tripletail::Filter';

# このフィルタはリンクのQUERY_STRINGを次のようにPATH_INFOに変換する。
#
# <a href="foo.cgi?Command=Foo&mode=1&SEO=1">
# 　　　　　　　　↓
# <a href="foo/Command/Foo/mode/1">
#
# クエリの中にキーワードSEO=1を含んでいるもののみを対象とし、
# リンク変換後にはSEO=1は消去する。
#
#
# また、head要素内にbase要素を追加する。
# head要素が存在しない場合はbody要素開始直前にhead要素が挿入されるが、
# body要素も存在しなければ何も挿入されない。
# 元々base要素が存在した場合はそのhref属性が置き換えられる。
#
# REQUEST_URI: http://foo.com/bar/baz.cgi
# 挿入される要素: <base href="http://foo.com/bar/">

# オプション一覧:
# * hide_extension => リンク変換の際、拡張子を削除するかどうか。デフォルト1。

# 注意:
# * このフィルタはTripletail::Filter::HTMLやTripletail::Filter::MobileHTMLよりも
#   後に実行されるように設定しなければならない。
# * Tripletail::Filter::HTML, Tripletail::Filter::MobileHTML がタグの途中で区切って
#   出力を行わない性質に依存している。
#   それ以外のカスタムフィルタと兼用する場合はその点を注意する
#   必要がある。
# * JISコードでの出力時は正常に動作しない。
# * charsetにはTripletail::Filter::HTMLまたはTripletail::Filter::MobileHTMLと
#   同じ文字コードを指定しなければならない。

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	my $defaults = [
		[charset     => 'Shift_JIS'],
		[hide_extension => 1],
	];
	$this->_fill_option_defaults($defaults);

	my $check = {
		charset        => [qw(defined no_empty scalar)],
		hide_extension => [qw(scalar)],
	};
	$this->_check_options($check);
	
	$this->reset;

	$this;
}

sub print {
	my $this = shift;
	my $str = shift;

	if(ref($str)) {
		die __PACKAGE__."#print: arg[1] is a reference. [$str] (第1引数がリファレンスです)\n";
	}

	$this->_filter($str);
}

sub flush {
	my $this = shift;

	'';
}

sub setOrder {
	my $this = shift;
	my @order = @_;

	my $count = 0;
	foreach my $data (@order) {
		$count++;
		if(ref($data)) {
			die __PACKAGE__."#setOrder: arg[$count] is a reference. [$data] (第${count}引数がリファレンスです)\n";
		}
	}

	$this->{order} = \@order;

	$this;
}

sub toLink {
	my $this = shift;
	my $form = shift;
	my $base = shift;

	if(!defined($form)) {
		die __PACKAGE__."#toLink: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($form) ne 'Tripletail::Form') {
		die __PACKAGE__."#toLink: arg[1] is not an instance of Tripletail::Form. [$form]. (第1引数がFormオブジェクトではありません)\n";
	}
	if(ref($base)) {
		die __PACKAGE__."#toLink: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}

	$form = $form->clone->delete('SEO');
	my $link = $form->toLink($base);
	my $query = $TL->newForm($TL->unescapeTag($link));

	$this->__makeLink($link, $query);
}

sub reset {
	my $this = shift;

	$this->SUPER::reset();
	$this->{header_skipped} = undef; # HTTPヘッダ部を通過した後であれば1
	$this->{rebased} = undef; # base要素を書換え、若しくは追加した後であれば1
	$this->{order} = []; # 出力順の指定

	$this;
}

sub _filter {
	my $this = shift;
	my $str = shift;

	my $header = '';
	if(!$this->{header_skipped}) {
		# HTTPヘッダ部を通過するまで何もしない。
		while($str =~ s/^(.+?\r?\n)//) {
			$header .= $1;

			if($1 !~ m/\S/) {
				# ヘッダ終了
				$this->{header_skipped} = 1;
				last;
			}
		}
	}

	if(length($str)) {
		$str = $this->_rebase($str);
		$str = $this->_relink($str);
	}

	$header . $str;
}

sub _rebase {
	my $this = shift;
	my $html = shift;

	if($this->{rebased}) {
		return $html;
	}

	my $filter = $TL->newHtmlFilter(
		interest => [qw[/head base body]],
	);
	$filter->set($html);

	my $baseurl = $ENV{REQUEST_URI} || '';
	$baseurl =~ s![^/]+$!!;
	if(!length($baseurl)) {
		# REQUEST_URIが与えられていないので何も出来ない。
		return $html;
	}
	$baseurl = sprintf(
		'%s://%s%s',
		($ENV{HTTPS} and $ENV{HTTPS} eq 'on') ? 'https' : 'http',
		$ENV{SERVER_NAME},
		$baseurl,
	);

	while(my ($context, $elem) = $filter->next) {
		if($this->{rebased}) {
			next;
		}

		if($elem->name eq 'base') {
			my $target = $elem->attr('target');

			if(!defined($target) || $target eq '_self') {
				$elem->attr(href => $baseurl);
				$this->{rebased} = 1;

				#$TL->log(
				#	__PACKAGE__,
				#	sprintf(
				#		'Modified existent base element: [%s] => [%s]',
				#		$elem->attr('href'), $baseurl)
				#);
			}
		} elsif($elem->name eq '/head') {
			# 直前に挿入。
			my $base = $context->newElement('base');
			$base->attr(href => $baseurl);

			$context->delete;
			$context->add($base);
			$context->add($elem);

			$this->{rebased} = 1;

			#$TL->log(
			#	__PACKAGE__,
			#	sprintf(
			#		'Inserted base element before the end of head element: [%s]',
			#		$baseurl)
			#);
		} elsif($elem->name eq 'body') {
			# 直前にheadを挿入。
			$context->delete;
			$context->add($context->newElement('head'));

			my $base = $context->newElement('base');
			$base->attr(href => $baseurl);
			$context->add($base);

			$context->add($context->newElement('/head'));
			$this->{rebased} = 1;

			#$TL->log(
			#	__PACKAGE__,
			#	sprintf(
			#		'Inserted head and base elements before the beginning of body element: [%s]',
			#		$baseurl)
			#);
		}
	}

	$filter->toStr;
}

sub _relink {
	my $this = shift;
	my $html = shift;

	my $filter = $TL->newHtmlFilter(
		interest => ['a', 'form'],
	);
	$filter->set($html);

	while(my ($context, $elem) = $filter->next) {
		if($elem->name eq 'a') {
			my $link = $elem->attr('href');
			defined $link or next;
	
			my $query = $TL->newForm($TL->unescapeTag($link));
			if($query->get('SEO')) {
				# 対象になっている
				$query->delete('SEO');
	
				my $new_url = $this->__makeLink($link, $query);
	
				$elem->attr(href => $new_url)
			}
		} elsif($elem->name eq 'form') {
			$elem->attr(EXT => undef);
		}
	}

	$filter->toStr;
}

sub __makeLink {
	my $this = shift;
	my $link = shift;
	my $query = shift;

	local($_);

	my @params;
	foreach my $key (@{$this->{order}}) {
		if($query->exists($key)) {
			foreach my $value (sort $query->getValues($key)) {
				push(@params, $key, $value);
			}
			$query->delete($key);
		}
	}
	foreach my $key (sort $query->getKeys) {
		next if($key eq 'INT');
		foreach my $value (sort $query->getValues($key)) {
			push(@params, $key, $value);
		}
	}

	my $path_info = join(
		'/', map {
			$TL->encodeURL($_);
		} @params);

	if(defined($_ = $query->getFragment)) {
		$path_info .= '#' . $TL->encodeURL($_);
	}

	(my $file = $link) =~ s/\?.*$//;

	if($this->{option}{hide_extension}) {
		$file =~ s/\..+$//;		# 拡張子を消す
	}

	my $new_url = $file . ($path_info ? "/$path_info" : '');
	#$TL->log(__PACKAGE__, sprintf ('Relinked: [%s] => [%s]', $elem->attr('href'), $new_url));

	$new_url;
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::Filter::SEO - SEO出力フィルタ

=head1 SYNOPSIS

  $TL->setContentFilter('Tripletail::Filter::HTML');
  $TL->setContentFilter(['Tripletail::Filter::SEO', 1001]);
 
  $TL->print($TL->readTextFile('foo.html'));

=head1 DESCRIPTION

このフィルタはリンクの C<QUERY_STRING> を次のように C<PATH_INFO> に変換する。

  <a href="foo.cgi?Command=Foo&mode=1&SEO=1">
  　　　　　　　　↓
  <a href="foo/Command/Foo/mode/1">

クエリの中にキーワードSEO=1を含んでいるもののみを対象とし、
リンク変換後にはSEO=1は消去する。

また、head要素内にbase要素を追加する。head要素が存在しない場合は
body要素開始直前にhead要素が挿入されるが、body要素も存在しなければ
何も挿入されない。元々base要素が存在した場合はそのhref属性が置き換えられる。

  REQUEST_URI: http://foo.com/bar/baz.cgi
  挿入される要素: <base href="http://foo.com/bar/">


注意:

このフィルタは L<Tripletail::Filter::HTML> や L<Tripletail::Filter::MobileHTML>
よりも後に実行されるように設定しなければならない。

また、リンクを書き換えた場合、そのリクエストは L<Tripletail::InputFilter::SEO>
を使用しなければ正常に受け取れない。

出力は Shift_JIS，EUC-JP，UTF-8 のいずれかでなければならない。
JIS コードの場合は正常に動作しない。


=head2 METHODS

=over 4

=item setOrder

  $TL->getContentFilter(1001)->setOrder(qw(ID Name));

SEO変換時に、出力するキーの順序を指定します。
指定されていないキーは、setOrder で指定されたキーの後に文字列順にソートされて出力されます。

=item toLink

  $TL->getContentFilter(1001)->toLink($TL->newForm(KEY => 'VALUE'));

フォームオブジェクトを、SEO変換と同様の形でリンクに変換します。

=item flush

L<Tripletail::Filter>参照

=item print

L<Tripletail::Filter>参照

=item reset

L<Tripletail::Filter>参照

=back

=head2 フィルタパラメータ

=over 4

=item hide_extension

  $TL->setContentFilter(['Tripletail::Filter::SEO', 1001], hide_extension => 0);

リンク変換の際、拡張子を削除するかどうか。省略可能。デフォルトは1。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Filter>

=item L<Tripletail::Filter::HTML>

=item L<Tripletail::Filter::MobileHTML>

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
