# -----------------------------------------------------------------------------
# Tripletail::FileSentinel - ファイルの更新の監視
# -----------------------------------------------------------------------------
package Tripletail::FileSentinel;
use strict;
use warnings;
use Tripletail;
use File::Spec;

sub _HOOK_PRIORITY() { 1_000_000 } # 順序は問わない
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

sub watch {
	my $this = shift;
	my $fpath = shift;
	$fpath = File::Spec->rel2abs($fpath);

	my $lastmod = (stat($fpath))[9];
	if(!$lastmod) {
		die __PACKAGE__."#watch: failed to stat [$fpath]: $! (ファイルをstatできませんでした)\n";
	}

    if ($TL->INI->get(TL => filelog => 'update') eq 'full') {
        $TL->log(
            __PACKAGE__,
            sprintf(
                'Watching file [%s]: last modified time: [%s]',
                $fpath,
                scalar(localtime($lastmod))
               )
           );
    }

	$this->{lastmod}{$fpath} = $lastmod;
	$this;
}

sub autoWatch {
	my $this = shift;
	my $include = shift;
	my $exclude = shift;
	local $_;

	return unless defined $include || defined $exclude;

	my @targets = values %INC;
	@targets = grep  m{$include}, @targets if $include;
	@targets = grep !m{$exclude}, @targets if $exclude;

	foreach ( @targets ) {
		$TL->log(__PACKAGE__, " autoWatch(): $_");
		$this->watch($_);
	}

	$this;
}

sub _new {
	my $class = shift;
	my $this = bless {} => $class;

	$this->{lastmod} = {}; # {file path => epoch}

	if(defined($0)) {
		$this->watch($0);
	}
	my $filename = $TL->INI->_filename;
	if(defined($filename)) {
		$this->watch($filename);
	}

	$this->autoWatch(
		$TL->INI->get(FileSentinel => autowatch_include => undef),
		$TL->INI->get(FileSentinel => autowatch_exclude => undef)
	);

	$this;
}

sub __postRequest {
	my $this = shift;

	while(my ($fpath, $lastmod) = each %{$this->{lastmod}}) {
		my $current = (stat($fpath))[9];
		if(!$current) {
			die __PACKAGE__."#postRequest: failed to stat [$fpath]: $! (ファイルをstatできませんでした)\n";
		}

		if($current != $lastmod) {
			my $time = localtime($current);

			$TL->log("File Update: file [$fpath] has been updated at [$time]");
			$TL->_fcgi_restart(1);
		}
	}
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::FileSentinel - ファイルの更新の監視

=head1 SYNOPSIS

  my $fsenti = $TL->getFileSentinel;

  $fsenti->watch('/etc/passwd');
  $fsenti->watch('/var/log/wtmp');

=head1 DESCRIPTION

FCGI モードの際に、特定のファイルが更新されたかどうかを調べて、
更新を検出した場合にプロセスを再起動する。このモジュールは
FCGI モードで自動的に使用され、FCGI モードでない時には使用されない。

=head2 METHODS

=over 4

=item C<< $TL->getFileSentinel >>

  my $fsenti = $TL->getFileSentinel;

Tripletail::FileSentinel オブジェクトを取得。

=item C<< watch >>

  $fsenti->watch('/var/log/wtmp');

監視対象のファイルを追加する。デフォルトでは次のファイルが
監視対象になっている。

=over 4

=item * プロセスの起動に用いられたスクリプト ($0)

=item * C<< use Tripletail qw(foo.ini); >> した時の ini ファイル

=back

=item C<< autoWatch >>

  $fsenti->autoWatch($include_re, $exclude_re);

do, require, use されたファイルを自動的に監視対象に追加する。
具体的には autoWatch の実行時点で %INC に含まれるファイルが監視対象となる。
$include_re, $exclude_re には正規表現を指定する。どちらも指定しなかった場合、 autoWatch は何もしない。
$include_re だけを指定した場合はこれにマッチするパスのファイルが、 $exclude_re だけを指定した場合はこれにマッチしないパスのファイルが、両方を指定した場合は $include_re にマッチして $exclude_re にマッチしないパスのファイルが監視対象となる。
Ini パラメータによる自動監視設定を使用すれば、通常プログラム中で autoWatch を直接呼ぶ必要はないが、 require や do でロードしたファイルを自動監視対象に含めたい場合は require, do の実行後に autoWatch を呼ぶ必要がある。

=back

=head2 Ini パラメータ

"FileSentinel" グループに autowatch_include または autowatch_exclude を指定すると、 use でロードされたモジュールのうち、条件にマッチするものが自動的に監視対象に追加される。
この機能を使用すれば、スクリプトごとに依存モジュールを watch で指定する必要がなくなる。パフォーマンスを考慮して、 /lib, /usr/lib 等に含まれる、通常は変更しないファイルは autowatch_exclude で監視対象から外すとよい。

=over 4

=item autowatch_include

  autowatch_include = ^/home/me/my_perl_modules

自動監視対象に含めたいパスを正規表現で指定する。
autowatch_include だけを指定した場合、マッチしたパスのファイルが全て監視対象となる。

=item autowatch_exclude

  autowatch_exclude = ^/usr/lib/|^/lib/

自動監視対象から除外したいパスを正規表現で指定する。
autowatch_exclude だけを指定した場合、マッチしないパスのファイルが全て監視対象となる。 autowatch_include と一緒に指定した場合は、 autowatch_include にマッチし、 autowatch_exclude にマッチしないパスのファイルが監視対象となる。

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::MemorySentinel>

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
