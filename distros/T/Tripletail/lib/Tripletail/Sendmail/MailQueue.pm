# -----------------------------------------------------------------------------
# Tripletail::Sendmail::MailQueue - 独自のメールキューを使用するメール送信
# -----------------------------------------------------------------------------
package Tripletail::Sendmail::MailQueue;
use base 'Tripletail::Sendmail';
use strict;
use warnings;
use Tripletail;
use Tripletail::Sendmail::Smtp;
use Unicode::Japanese ();

our $QUEUE_ID_COUNT = 0;

1;

sub _new {
	my $class = shift;
	my $group = shift;
	my $this = bless {} => $class;

	local($_);

    $this->{queuedir} = do {
        my $queuedir = $TL->INI->get($group => 'queuedir');
        $queuedir =~ s!/+$!!; # 末尾の / を消す
        $queuedir;
    };

	$this->{group} = $group;
	$this->{smtp} = Tripletail::Sendmail::Smtp->_new($group);
	$this->{erroraddr} = $TL->INI->get($group => 'erroraddr' => undef);
	$this->{errorlog} = $TL->INI->get($group => 'errorlog' => undef);
	$this->{host} = $TL->INI->get($group => 'host');

	if(defined($_ = $TL->INI->get($group => 'timeout' => undef))) {
		$this->{smtp}->setTimeout($_);
	}

	$this;
}

sub setTimeout {
	my $this = shift;

	$this->{smtp}->setTimeout(@_);
}

sub send {
	my $this = shift;
	my $data = $this->_getoptSend(@_);

	my $fname = sprintf 'TL-%d-%d-%d', time, $$, $QUEUE_ID_COUNT++;
	my $infile = "$this->{queuedir}/incoming/$fname";
	my $queuefile = "$this->{queuedir}/queue/$fname";

	open my $fh, '>', $infile
		or die __PACKAGE__."#send: failed to write file [$infile] (ファイルに書き込めません)\n";

	print $fh "$data->{from}\r\n";
	foreach my $rcpt (@{$data->{rcpt}}) {
		print $fh "$rcpt\r\n";
	}
	print $fh "\r\n";

	$data->{data} =~ s/\r?\n|\r/\r\n/g;
	print $fh $data->{data};

	close $fh;

	rename $infile => $queuefile
		or die __PACKAGE__."#send: failed to rename [$infile] => [$queuefile] (リネームできません)\n";

	$this;
}

sub process {
	my $this = shift;

	local($_);

	# 最初にrecover実行
	$this->_recover;

	my $queue = "$this->{queuedir}/queue";
	opendir my $dh, $queue
		or die __PACKAGE__."#process: failed to opendir [$queue]. (ディレクトリを開けません)\n";

	while(defined($_ = readdir $dh)) {
		my $fname = $_;

		my $queuefile = "$queue/$fname";
		-f $queuefile or next;

		my $outfile = "$this->{queuedir}/outgoing/$fname.$$";
		rename $queuefile => $outfile
			or die __PACKAGE__."#process: failed to rename [$queuefile] => [$outfile] (リネームできません)\n";

		eval {
			if($this->_tryToSend($outfile)) {
				# 成功
				unlink $outfile
					or die __PACKAGE__."#process: failed to unlink [$outfile] (ファイルを削除できません)\n";
			} else {
				# 一時的失敗
				my $deferral = "$this->{queuedir}/queue/$fname";
				rename $outfile => $deferral
					or die __PACKAGE__."#process: failed to rename [$outfile] => [$deferral] (リネームできません)\n";
			}
		};
		if(my $error = $@) {
			# 永続的失敗
			my $data = do {
				local $/ = undef;

				open my $fh, '<', $outfile
					or die __PACKAGE__."#process: failed to read [$outfile] (ファイルを読めません)\n";
				<$fh>;
			};
			$data = Unicode::Japanese->new($data, 'auto')->get;
			$data =~ s/\r?\n|\r/\n/g;

			unlink $outfile
				or die __PACKAGE__."#process: failed to unlink [$outfile] (ファイルを削除できません)\n";

			if($this->{errorlog}) {
				$TL->log(
					__PACKAGE__,
					"Failed to send the following message permanently:\n".
					"$data\n\n".
					"Error:\n$error"
				);
			}

			if($this->{erroraddr}) {
				my $addr = $this->{erroraddr};
				my $host = 'localhost';

				if($addr =~ s/%(.+)$//) {
					$host = $1;
				}

				my $mail = $TL->newMail;
				my $from = 'null@'.$mail->_getHostname.'';

				$mail->setHeader(
					From => "Tripletail::Sendmail::MailQueue <$from>",
					To   => $addr,
					Subject => "Tripletail::Sendmail::MailQueue 配送失敗",
				);
				$mail->setBody(
					"以下のメールの配送に失敗しました:\n\n".
					"$data\n\n".
					"エラー:\n$error"
				);

				my $smtp = Tripletail::Sendmail::Smtp->_new($this->{group});
				$smtp->connect($host);
				$smtp->send(
					rcpt => $addr,
					from => $addr,
					data => $mail->toStr,
				);
				$smtp->disconnect;
			}
		}
	}

	closedir $dh;
}

sub _tryToSend {
	# 永続的失敗が起こった場合はdieする。
	my $this = shift;
	my $fname = shift;

	my $data = do {
		local $/ = undef;

		open my $fh, '<', $fname
			or die __PACKAGE__."#process: failed to read file [$fname] (ファイルを読めません)";
		<$fh>;
	};

	# エンベロープFROM, エンベロープTOを読み出す
	$data =~ s/^(.+?)\r\n// or die;
	my $from = $1;

	my $rcpt = [];
	while($data =~ s/^(.*?)\r\n//) {
		if(length $1) {
			push @$rcpt, $1;
		} else {
			last;
		}
	}

	eval {
		$this->{smtp}->connect($this->{host});
	};
	if($@) {
		# 繋がらない => 一時失敗
		$TL->log(__PACKAGE__, $@);
		return undef;
	}

	eval {
		$this->{smtp}->send(
			rcpt => $rcpt,
			from => $from,
			data => $data,
		);
	};
	if($@) {
		if($this->{smtp}->_getResultCode =~ m/^4/) {
			# 一時失敗
			$TL->log(__PACKAGE__, $@);
			return undef;
		} else {
			# 永続的失敗
			die $@;
		}
	} else {
		$TL->log(__PACKAGE__, "sent [$fname] successfully");
	}

	eval {
		$this->{smtp}->disconnect;
	};
	if($@) {
		$TL->log(__PACKAGE__, $@);
	}

	# 成功
	return 1;
}

sub _recover {
	my $this = shift;
	$this->_recover_incoming;
	$this->_recover_outgoing;
}

sub _recover_incoming {
	my $this = shift;

	local($_);

	my $incoming = "$this->{queuedir}/incoming";

	opendir my $dh, $incoming
		or die __PACKAGE__."#process: failed to opendir [$incoming] (ディレクトリを開けません)\n";

	while(defined($_ = readdir $dh)) {
		my $fname = $_;
		my $fpath = "$incoming/$fname";

		if(-f $fpath && $fname =~ m/^TL-\d+-(\d+)-/) {
			my $pid = $1;

			# このプロセスが生きているかどうかをkill 0で調べる。
			if(kill 0, $pid) {
				# 生きているので弄らない。
				next;
			} else {
				# 死んでいるので消す
				$TL->log(
					__PACKAGE__,
					"Incoming mail [$fpath] seems to be an orphan. Deleting..."
				);

				unlink $fpath
					or die __PACKAGE__."#process: failed to unlink [$fpath] (ファイルを削除できません)";
			}
		}
	}

	closedir $dh;
}

sub _recover_outgoing {
	my $this = shift;

	local($_);

	my $outgoing = "$this->{queuedir}/outgoing";
	my $queue = "$this->{queuedir}/queue";

	opendir my $dh, $outgoing
		or die __PACKAGE__."#process: failed to opendir [$outgoing] (ディレクトリを開けません)\n";

	while(defined($_ = readdir $dh)) {
		my $fname = $_;
		my $fpath = "$outgoing/$fname";

		if(-f $fpath and $fpath =~ m/\.(\d+)$/) {
			my $pid = $1;

			# このプロセスが生きているかどうかをkill 0で調べる。
			if(kill 0, $pid) {
				# 生きているので弄らない。
				next;
			} else {
				# 死んでいるのでqueueに戻す。
				$TL->log(
					__PACKAGE__,
					"Outgoing mail [$fpath] seems to be an orphan. Requeueing..."
				);

				my $requeue = "$queue/$fname";
                $requeue =~ s/\.\d+$//; # pid を消す
				rename $fpath => $requeue
					or die __PACKAGE__."#process: failed to rename [$fpath] => [$requeue] (リネームできません)\n";
			}
		}
	}

	closedir $dh;
}


__END__

=encoding utf-8

=for stopwords
	Ini
	TripletaiL
	YMIRLINK
	erroraddr
	errorlog
	mailqueue
	mailqueue-process
	mailqueue-recover
	queuedir
	setTimeout
	smtp

=head1 NAME

Tripletail::Sendmail::MailQueue - 独自のメールキューを使用するメール送信

=head1 SYNOPSIS

  my $smail = $TL->newSendmail('SendMailQueue');
  
  $smail->send(...);
  $smail->send(...);
  $smail->send(...);
  
  $smail->process;

=head1 DESCRIPTION

送信要求されたメールを、 TripletaiL のメールキューに保存する．

キュー内に保存されたメールは、L</"process"> 呼び出し時に一括して配送される。

=head2 METHODS

=over 4

=item new
  
L<Tripletail::Sendmail> 参照。

=item connect

=item disconnect

何もしない。

=item setTimeout

L<Tripletail::Sendmail::Smtp> 参照。配信時のタイムアウト時間を設定する。

=item send

L<Tripletail::Sendmail> 参照。

=item process

  $smail->process

実際の配信処理を行う。一般にこのメソッドは処理に時間が掛かる為、
CGIのプロセスから直接呼ぶべきではない。

=back


=head2 Ini パラメータ

=over 4

=item queuedir

  queuedir = /home/www/mqueue/

メールキューディレクトリ。

=item timeout

=item host

L<Tripletail::Sendmail::Smtp> 参照

=item erroraddr

  erroraddr = null@example.org%localhost

配信エラー時にエラーメールを送るなら、その送信先を指定。

C<< null@example.org%localhost >> のように使用する smtp サーバーを指定する。
C<%> 以降は省略可能で、省略された場合は C<localhost> となる。

=item errorlog

  errorlog = 1

配信エラー時にエラーログを記録するかどうか。
0の場合、保存しない。
1の場合、保存する。

=back


=head2 実装

=over 4

=item メールキュー

メールキューのディレクトリには、queue,incoming,outgoing の３つのディレクトリが
作成済みで、同一のパーティションになければならない。

メールは、１行目にエンベロープFrom、２行目以降にエンベロープToが１行１アドレスで
あり、空行を挟み、その後に本文データが続く。改行コードは C<\r\n> とする。

=item 送信時 (Tripletail::MailQueue)

新規にキューにメールを入れる場合は、incoming ディレクトリ内に作成してから
queue へ rename(2) する。ファイル名は、時刻、プロセスID等を使い、
ユニークになるようなものとする。

=item 配信時 (mailqueue-process)

メールを処理するときは，outgoing に rename してから処理を行い、終わったら
C<rm> する。C<rename(2)> する際、ファイル名の末尾に「.」とプロセスIDを記述する。

メールを定期的に調査し、設定されたMTAへSMTPで送信を行う。failure の場合は
指定アドレスにメールを送るか、ログに書き込む（設定で変更可能）。deferral
の場合は queue ディレクトリに rename(2) で戻す。末尾の .$pid は削除する。

=item 修復 (mailqueue-recover)

プロセスが存在しないのに、outgoing にファイルがある場合は、deferral として
queue ディレクトリにrename(2) で戻す。末尾の .$pid は削除する。

プロセスが存在しないのにincomingにファイルがある場合は、それを削除する。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

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
