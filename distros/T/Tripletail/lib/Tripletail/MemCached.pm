# -----------------------------------------------------------------------------
# Tripletail::MemCached - キャッシュを扱う
# -----------------------------------------------------------------------------
package Tripletail::MemCached;
use Tripletail;
use strict;
use warnings;

1;

sub _new {
	my $class = shift;
	my $this = bless {} => $class;

	my @servers;

	$this->{servers} = $TL->INI->get('MemCached' => servers => undef);
	if(!defined($this->{servers})) {
		push(@servers,'localhost:11211');
	} else {
		foreach my $tmp (split(/\s+/, $this->{servers})) {
			push(@servers,split(/\s?,\s?/, $tmp));
		}
	}
	
	$this->{servers} = \@servers;
	$this->{compress_threshold} = $TL->INI->get('MemCached' => 'compress_threshold', '10000');

	my $xs = $TL->INI->get('MemCached' => 'xs', '1');

	if($xs == 1) {
		do {
			local $SIG{__DIE__} = 'DEFAULT';
			eval 'use Cache::Memcached::XS';
		};
		if($@) {
			do {
				local $SIG{__DIE__} = 'DEFAULT';
				eval 'use Cache::Memcached';
			};
			if($@) {
				die "TL#newMemCached: failed to load Cache::Memcached [$@] (Cache::Memcachedを使用できません)\n";
			}
		}
	} else {
		do {
			local $SIG{__DIE__} = 'DEFAULT';
			eval 'use Cache::Memcached';
		};
		if($@) {
			die "TL#newMemCached: failed to load Cache::Memcached [$@] (Cache::Memcachedを使用できません)\n";
		}
	}
	

	$this->{memd} = Cache::Memcached->new({
		'servers' => $this->{servers},
		'debug' => 0,
		'compress_threshold' => $this->{compress_threshold},
	});
	

	$this;
}

sub set {
	my $this = shift;
	my $key = shift;
	my $value = shift;
	my $expires = shift;

	if(!defined($key)) {
		die __PACKAGE__."#set: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#set: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($key =~ /\s/) {
		die __PACKAGE__."#set: arg[1] has a space. (第1引数がスペースを含んでいます)\n";
	}

	if(!defined($value)) {
		die __PACKAGE__."#set: arg[2] is not defined. (第2引数が指定されていません)\n";
	}
	
	my $data = $this->{memd}->set($key, $value, $expires);
}

sub get {
	my $this = shift;
	my $key = shift;

	if(!defined($key)) {
		die __PACKAGE__."#get: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#get: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($key =~ /\s/) {
		die __PACKAGE__."#get: arg[1] has a space. (第1引数がスペースを含んでいます)\n";
	}

	$this->{memd}->get($key);
}

sub delete {
	my $this = shift;
	my $key = shift;

	if(!defined($key)) {
		die __PACKAGE__."#delete: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#delete: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($key =~ /\s/) {
		die __PACKAGE__."#delete: arg[1] has a space. (第1引数がスペースを含んでいます)\n";
	}

	$this->{memd}->delete($key);
}

sub disconnect_all {
	my $this = shift;

	$this->{memd}->disconnect_all;
}

sub flush_all {
	my $this = shift;

	$this->{memd}->flush_all;
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::MemCached - キャッシュを扱う

=head1 SYNOPSIS

  #キャッシュにセット
  $TL->newMemCached->set($key,$data);
  
  #キャッシュから取得
  my $cachedata = $TL->newMemCached->get($key);
  
  #キャッシュから削除
  $TL->newMemCached->delete($key);

=head1 DESCRIPTION

memcachedを利用するためのクラスです。
Cache::Memcached::XSを使用しています。
Cache::Memcached::XSが利用不可能な場合、Cache::Memcachedを利用しようとします。（デフォルト設定の場合）

=head2 METHODS

=over 4

=item $TL->newMemCached

  $memc = $TL->newMemCached;

Tripletail::MemCached オブジェクトを作成。

=item set

  $memc->set($key, $data)
  $memc->set($key, $data, $expires)

$keyをキーとして、$dataをメモリキャッシュに書き込む。
$expiresがキャッシュの保持期限となる。
	
$expires が省略された場合は 60*60*24*30が使われる。

キャッシュに成功した場合1が、失敗した場合0が返る。

=item get

  $cachedata = $memc->set($key)

指定したキーにセットされているキャッシュを読み込む
キャッシュが無かった場合、undefが返る。

=item delete

  $memc->delete($key)

指定したキーにセットされているキャッシュを削除する。

=item disconnect_all
	
  $memc->disconnect_all

コネクションを解放する。forkした場合に利用する。
親プロセスでコネクションすると、子プロセスでもそのキャッシュされたソケットを利用しようとするため。

=item flush_all

  $memc->flush_all

存在する全てのキャッシュを削除する。


=back


=head2 Ini パラメータ

グループ名は "MemCached" でなければならない。

例:

  [MemCached]
  servers = localhost:11211
  compress_threshold = 10000

=over 4

=item servers

  servers = localhost:11211 10.0.0.17:11211,3

接続するMemCachedサーバを指定する。省略可能。
スペース区切りで複数指定可能。,で重み付け可能。指定しない場合の重みは1。

デフォルトは "localhost:11211" 。

=item compress_threshold

  compress_threshold = 10000

指定された以上のbytesのデータの場合圧縮する。

デフォルトは "10000"。

=item xs

  xs = 1

0の場合、Cache::Memcachedを利用する。
1の場合、Cache::Memcached::XSを利用する。但し、Cache::Memcached::XSが利用不可能だった場合は、Cache::Memcachedの利用を試みる。

デフォルトは "1"。

=back

=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
