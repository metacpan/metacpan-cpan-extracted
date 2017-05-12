# -----------------------------------------------------------------------------
# Tripletail::MemorySentinel - メモリ使用状況の監視
# -----------------------------------------------------------------------------
package Tripletail::MemorySentinel;
use strict;
use warnings;
use Tripletail;

sub _HOOK_PRIORITY() { 2_000_000 } # 順序は問わない
our $_INSTANCE;

1;

sub _getInstance {
	my $class = shift;

	if(!$_INSTANCE) {
		$_INSTANCE = $class->_new(@_);
	}

	$_INSTANCE;
}

sub __install {
	my $this = shift;

	$TL->setHook('postRequest', _HOOK_PRIORITY, sub { $this->__postRequest });
}

sub _new {
	my $class = shift;
	my $this = bless {} => $class;

	$this->{getmemfunc} = undef; # メモリ使用量を取得する為の関数。'NONE'なら存在しない。
	$this->{getmemfh} = undef;
	$this->{initial} = undef; # 最初のpostRequestの時点でのメモリ使用量
	$this->{permissible} = {}; # {key => size} 用途別のメモリ使用許容量

	$this->setPermissibleSize(_HEAP => 10 * 1024); # 10 MiB
	$this;
}

sub getMemorySize {
	my $this = shift;

	if(!defined($this->{getmemfunc})) {
		my $uname = eval {
			$^O eq 'MSWin32' and die 'MSWin32 is not supported';
			`uname -sr`;
		};
		if($@) {
			$TL->log(__PACKAGE__, "Failed to exec `uname -sr`. [$@]");
			$uname = $^O;
		} else {
			$uname =~ s/^\s*|\s*$//g;
            
            if ($TL->INI->get(TL => memorylog => 'leak') eq 'full') {
                $TL->log(__PACKAGE__, "Uname is [$uname]");
            }
		}

		if($uname =~ m/^Linux 2\./) {
			$this->{getmemfunc} = \&__getMemLinux2;
		} else {
			$TL->log(__PACKAGE__, "We can't get memory usage on [$uname] currently...");
			$this->{getmemfunc} = 'NONE';
		}
	}

	if(ref($this->{getmemfunc})) {
		$this->{getmemfunc}($this);
	} else {
		0;
	}
}

sub setPermissibleSize {
	my $this = shift;
	my $key = shift;
	my $size = shift;

	$this->{permissible}{$key} = $size;
	$this;
}

sub getTotalPermissibleSize {
	my $this = shift;

	my $total = 0;
	foreach(values %{$this->{permissible}}) {
		$total += $_;
	}

	$total;
}

sub __getMemLinux2 {
	my $this = shift;
	local $/ = undef;

	my $fh = $this->{getmemfh};
	if(!defined($fh)) {
		unless(open $fh, '<', "/proc/$$/status") {
			$TL->log(__PACKAGE__, "Failed to read /proc/$$/status");
			return 0;
		}
		$this->{getmemfh} = $fh;
	} else {
		seek $fh, 0, 0;
	}

	my $stat = <$fh>;
	if($stat =~ m/^VmSize:\s*(\d+)/m) {
		return $1;
	} else {
		$TL->log(__PACKAGE__, "Failed to get VmSize from /proc/$$/status");
	}

	0;
}

sub __postRequest {
	my $this = shift;

	if(!defined($this->{initial})) {
		$this->{initial} = $this->getMemorySize;
	}

	my $initial = $this->{initial};
	my $current = $this->getMemorySize;
	my $allowed = $this->getTotalPermissibleSize;
	my $filecache = $TL->_filecacheMemorySize;
	my $remaining = $initial + $filecache + $allowed - $current;
	# [=initial=========][=filecache==][=allowed=======]
	# [=current==============================][=remain=]

	my $mem_usage = sprintf(
		"Memory Usage: \n".
		"  [current: %s KiB]\n".
		"  [initial: %s KiB]\n".
		"  [filecache: %s KiB]\n".
		"  [allowed: %s KiB]\n".
		"  [remaining: %s KiB]",
		$current, $initial, $filecache, $allowed, $remaining);

	my $switch = $TL->INI->get(TL => 'memorylog', 'leak');
	if (($switch eq 'leak' and $remaining < 0) or $switch eq 'full') {
		$TL->log(
			__PACKAGE__, $mem_usage);
	}

	if ($switch ne 'leak' and $switch ne 'full') {
		$TL->log(
			__PACKAGE__,
			sprintf('unknown [TL]memoryleak parameter: "%s"', $switch));
	}

	if ($remaining < 0) {
		$TL->log("Tripletail::MemorySentinel detected a possible memory leak.\n\n$mem_usage");
		$TL->_fcgi_restart(1);
	}
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::MemorySentinel - メモリ使用状況の監視

=head1 SYNOPSIS

  my $msenti = $TL->getMemorySentinel;
  $msenti->setPermissibleSize(db_cache => 10 * 1024);

  my $usage = $msenti->getMemorySize;

=head1 DESCRIPTION

FCGI モードの際に、メモリリークが発生しているかどうかを調べて、
リークを検出した場合にプロセスを再起動する。このモジュールは
FCGI モードで自動的に使用され、FCGI モードでない時には使用されない。

このモジュールは、最初に L<Tripletail/"Main関数"> を抜けた時の仮想メモリサイズを
保存する。そして次回以降に L<Tripletail/"Main関数"> を抜けた際、最初の時点に対する仮想
メモリサイズの増加が設定値を越えていれば、メモリリークが発生したと判断する。

=head2 METHODS

=over 4

=item C<< $TL->getMemorySentinel >>

  my $msenti = $TL->getMemorySentinel;

Tripletail::MemorySentinel オブジェクトを取得。

=item C<< getMemorySize >>

  my $usage = $TL->getMemorySize;

現在のメモリ使用量を取得する。

=item C<< setPermissibleSize >>

  $msenti->setPermissibleSize(db_cache => 10 * 1024);

許容メモリ使用量を設定する。
第一引数にはその設定に対するキーを渡し、第二引数にはサイズを KiB 単位で渡す。

デフォルトでは次の設定がされている。

  $msenti->setPermissibleSize(_HEAP => 10 * 1024);

=item C<< getTotalPermissibleSize >>

  my $total = $msenti->getTotalPermissibleSize;

全てのキーに対する許容メモリ使用量の合計値を返す。

=back


=head1 BUGS

現在の所、このモジュールは次の OS からのみメモリ使用量を取得する事が出来る。
これ以外の OS ではメモリリークの検出は行なわれない。

=over 4

=item * Linux 2.x

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::FileSentinel>

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
