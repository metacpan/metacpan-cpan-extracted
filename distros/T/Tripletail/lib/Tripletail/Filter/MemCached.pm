# -----------------------------------------------------------------------------
# Tripletail::Filter::MemCached - MemCachedを使用するときに使用するフィルタ
# -----------------------------------------------------------------------------
package Tripletail::Filter::MemCached;
use strict;
use warnings;
use Tripletail;
use base 'Tripletail::Filter';

# このフィルタは必ず最後に呼び出されなければならない。
# オプション一覧:
# * key     => MemCachedから読み込む際のキー
# * mode    => MemCachedへの書き込み(write)か、MemCachedからの出力(pass-through)か。
# * form    => 書き込み時に埋め込むデータ。Tripletail::Fromクラスの形で渡す。
# * formcharset => 書き込み時に埋め込むデータを変換するための、出力の文字コード。(UTF-8から変換される)
#                  デフォルト: Shift_JIS
# * cachedata   => メモリーにキャッシュされていたデータを渡す。


1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	# デフォルト値を埋める。
	my $defaults = [
		[formcharset => 'Shift_JIS'],
		[key     => undef],
		[mode    => 'in'],
		[form    => undef],
		[cachedata   => undef],
	];
	$this->_fill_option_defaults($defaults);

	# オプションのチェック
	my $check = {
		formcharset     => [qw(defined no_empty scalar)],
		key      => [qw(defined no_empty scalar)],
		mode     => [qw(defined no_empty scalar)],
		form     => [qw(no_empty)],
		cachedata       => [qw(no_empty scalar)],
	};
	$this->_check_options($check);

	if($this->{option}{mode} ne 'write' && $this->{option}{mode} ne 'pass-through') {
		die "TL#setContentFilter: option [mode] for [Tripletail::Filter::MemCache] ".
			"must be 'write' or 'pass-through', not [$this->{option}{mode}].".
			" (modeはwriteかpass-throughのいずれかを指定してください)\n";
	}
	
	if($this->{option}{mode} eq 'pass-through' && defined($this->{option}{cachedata})) {
		$this->{buffer} = $this->{option}{cachedata};
	} else {
		$this->{buffer} = '';
	}

	$this;
}

sub print {
	my $this = shift;
	my $data = shift;

	if(ref($data)) {
		die __PACKAGE__."#print: arg[1] is a reference. [$data] (第1引数がリファレンスです)\n";
	}
	
	return '' if($data eq '');
	
	if($this->{option}{mode} eq 'write') {
		$this->{buffer} .= $data;
	} else {
		if($this->{buffer} eq '') {
			$this->{buffer} = $data;
		} else {
			die __PACKAGE__."#print: some data have already been printed. (既に何らかの出力がされています)\n";
		}
	}
	
	'';
}

sub flush {
	my $this = shift;

	my $output;
	if($this->{option}{mode} eq 'write') {
		my $nowtime = time;
		$output = q{Last-Modified: } . $TL->newDateTime->setEpoch($nowtime)->toStr('rfc822') . qq{\r\n} . $this->{buffer};
		my $value = $nowtime . q{,} . $output;
		$TL->newMemCached->set($this->{option}{key},$value);
		if(defined($this->{option}{form})) {
			foreach my $key2 ($this->{option}{form}->getKeys){
				my $val = $TL->charconv($this->{option}{form}->get($key2), 'UTF-8' => $this->{option}{formcharset});
				$output =~ s/$key2/$val/g;
			}
		}
	} else {
		$output = $this->{buffer};
	}

	$output;
}

sub reset {
	my $this = shift;
	$this->SUPER::reset;
	
	$this->{buffer} = '';
	
	$this;
}



__END__

=encoding utf-8

=for stopwords
	MemCached
	YMIRLINK
	cachedata
	formcharset


=head1 NAME

Tripletail::Filter::MemCached - MemCached を使用するときに使用するフィルタ

=head1 SYNOPSIS

  $TL->setContentFilter('Tripletail::Filter::MemCached',key => 'key', mode => 'pass-through', form => $form,  formcharset => 'Shift_JIS',  cachedata => $cachedata);

=head1 DESCRIPTION

MemCached の使用を支援する。
このフィルタを使用する場合、最後に使用しなければならない。

=head2 METHODS

=over 4

=item flush

L<Tripletail::Filter>参照

=item print

L<Tripletail::Filter>参照

=item reset

L<Tripletail::Filter>参照

=back

=head2 フィルタパラメータ

=over 4

=item key

MemCached で使用する key を設定する。

=item mode

MemCached への書き込みか、 MemCached からの読み込みかを選択する。

C<write> で書き込み、C<pass-through>で読み込み。省略可能。

デフォルトはC<write>。

=item form

inで書き込みをする際に、出力文字列中に最後に埋め込みを行う情報をL<Tripletail::Form> クラスのインスタンスで指定する。
L<Tripletail::Form>クラスのキーが出力文字列中に存在している場合、値に置換する。省略可能。

=item formcharset

formの値をUTF-8から変換する際の文字コードを指定する。省略可能。

使用可能なコードは次の通り。
UTF-8，Shift_JIS，EUC-JP，ISO-2022-JP

デフォルトはShift_JIS。

=item cachedata

C<pass-through>時のみに使用される。
出力する MemCached のデータを渡す。
直接出力されるため、ヘッダや文字コードに注意する必要がある。

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Filter>

=item L<Tripletail::MemCached>

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
