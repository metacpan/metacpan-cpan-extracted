# -----------------------------------------------------------------------------
# Tripletail::Sendmail::Smtp - SMTPメール送信
# -----------------------------------------------------------------------------
package Tripletail::Sendmail::Smtp;
use strict;
use warnings;
use Tripletail;
use IO::Socket::INET;
use base 'Tripletail::Sendmail';

1;

sub _new {
	my $class = shift;
	my $group = shift;
	my $this = bless {} => $class;

	$this->{group  } = $group;
	$this->{timeout} = $TL->INI->get($group => timeout => 300        );
	$this->{host   } = $TL->INI->get($group => host    => 'localhost');
	$this->{log    } = $TL->INI->get($group => logging => undef      );
	$this->{sock   } = undef;
	$this->{status } = undef;

	$this->{timeout_period} = $TL->parsePeriod($this->{timeout});

	$this;
}

sub setTimeout {
	my $this = shift;
	my $sec = shift;

	if(ref($sec)) {
		die __PACKAGE__."#setTimeout: arg[1] is a reference. [$sec] (第1引数がリファレンスです)\n";
	}

	$this->{timeout} = $sec;
	$this->{timeout_period} = $TL->parsePeriod($this->{timeout});
	$this;
}

sub connect {
	my $this = shift;
	my $host = shift;

	if(!defined($host)) {
		# iniで指定されたものを使う
		$host = $this->{host};
	} elsif(ref($host)) {
		die __PACKAGE__."#connect: arg[1] is a reference. [$host] (第1引数がリファレンスです)\n";
	}

	$this->_connect($host);
	$this->_hello;

	$this;
}

sub disconnect {
	my $this = shift;

	$this->_quit;
	$this->_disconnect;

	$this;
}

sub send {
	my $this = shift;
	my $data = $this->_getoptSend(@_);

	$this->_reset;

	# send from

	$this->_resetBufferedNum;
	$this->_sendCommand("MAIL From:<$data->{from}>");
	if($this->{status}{resultcode} =~ m/^[45]/) {
		my $message = $this->{status}{resultmessage};
		$message =~ s/\n$//;
		$message =~ s,\n, / ,g;
		die __PACKAGE__."#send: MAIL From command failed. [$this->{status}{resultcode} $message] (MAIL From コマンドが失敗しました)\n";
	}

	# send rcpt
	foreach my $rcpt (@{$data->{rcpt}}) {
		if($this->{status}{extflag}{PIPELINING}) {
			$this->_sendCommand("RCPT To:<$rcpt>", 1);		# no wait
		} else {
			$this->_sendCommand("RCPT To:<$rcpt>");
		}
	}

	$this->_sendCommand("DATA", 1);

	if($this->{status}{extflag}{PIPELINING}) {
		$this->_waitReplyAll;
	}

	$this->_waitReply;
	if($this->{status}{resultcode} =~ m/^[45]/) {
		my $message = $this->{status}{resultmessage};
		$message =~ s/\n$//;
		$message =~ s,\n, / ,g;
		die __PACKAGE__."#send: DATA command failed. [$this->{status}{resultcode} $message] (DATAコマンドが失敗しました)\n";
		$this->_reset;
	}

	$this->_sendData($data->{data});

	$this;
}

sub _reset {
	my $this = shift;
	
	$this->_sendCommand("RSET");
	if($this->{status}{resultcode} =~ m/^[45]/) {
		my $message = $this->{status}{resultmessage};
		$message =~ s/\n$//;
		$message =~ s,\n, / ,g;
		die __PACKAGE__."#send: RSET command failed. [$this->{status}{resultcode} $message] (RSETコマンドが失敗しました)\n";
	}
}

sub _setLogging {
	my $this = shift;
	my $flag = shift;
	
	$this->{log} = $flag;
	
	$this;
}

sub _log {
	my $this = shift;
	my $mes = shift;

	if($this->{log}) {
		$mes =~ s/\n?$/\n/;
		$TL->log(__PACKAGE__, $mes);
	}

	$this;
}

sub _connect {
	my $this = shift;
	my $host = shift;

	delete $this->{status};

	$this->{host} = $host;

	$this->{port} = '25';
	if($this->{host} =~ s/:(.*)$//) {
		$this->{port} = $1;
	}

	# connect

	$this->_log("connect...");

	local($SIG{ALRM});

	$SIG{ALRM} = sub { die __PACKAGE__."#connect: connection has timed out. (接続がタイムアウトしました)\n"; };
	alarm($this->{timeout_period});

	$this->{sock} = IO::Socket::INET->new(
		PeerAddr => $this->{host},
		PeerPort => $this->{port},
		Proto => 'tcp',
		Timeout => $this->{timeout_period},
	);

	alarm(0);
	if(!$this->{sock}) {
		die __PACKAGE__."#connect: failed to connect: [$this->{host}:$this->{port}][$!] (接続に失敗しました)\n";
	}

	$this->_log("--> ok.");

	$this->_waitReply;

	$this;
}

sub _hello {
	my $this = shift;

	$this->_log("[hello]");

	my $myhost = $this->_getHostname;
	$this->_sendCommand("EHLO $myhost");
	if($this->{status}{resultcode} =~ m/^5/) {
		$this->_sendCommand("HELO $myhost");
	} else {
		foreach my $line (split(/\n/, $this->{status}{resultmessage})) {
			next if($line !~ m/^[\w\d]+$/);
			$this->{status}{extflag}{$line} = 1;
		}
		$this->_log("extflag: " . join(' ', (keys %{$this->{status}{extflag}})));
	}

	$this;
}

sub _getHostname {
	my $this = shift;

	# state var.
	our $hostname;

	if(!defined($hostname)) {
		$hostname = $TL->_hostname();
		chomp $hostname;
	}

	$hostname;
}

sub _quit {
	my $this = shift;

	$this->_log("[quit]");
	$this->_sendCommand("QUIT");
}

sub _disconnect {
	my $this = shift;

	$this->_log("[disconnect]");

	local($SIG{ALRM});

	$SIG{ALRM} = sub { die __PACKAGE__."#disconnect: disconnection has timed out. (closeがタイムアウトしました)\n"; };
	alarm($this->{timeout_period});
	my $closeresult = close($this->{sock});
	alarm(0);
	if(!$closeresult) {
		die __PACKAGE__."#disconnect: failed to close. [$!] (接続のcloseに失敗しました)\n";
	}

	delete $this->{sock};

	$this->_log("--> ok.");

	$this;
}

sub _resetBufferedNum {
	my $this = shift;

	$this->{bufferedcommand} = 0;

	$this;
}

sub _sendCommand {
	my $this = shift;

	my $buffnummax = 100;

	my $command = shift;
	my $nowaitflag = shift;

	my $sock = $this->{sock};

	local($SIG{ALRM});

	$SIG{ALRM} = sub { die __PACKAGE__."#_sendCommand: command transfer has timed out: [$command]($nowaitflag) (コマンド送信がタイムアウトしました)\n"; };
	$this->_log("send>> $command");
	local($\) = '';
	alarm($this->{timeout_period});
	print $sock "$command\r\n";
	alarm(0);

	$this->{bufferedcommand}++;

	if((!$nowaitflag) || ($this->{bufferedcommand} > $buffnummax)) {
		$this->_waitReply;
		$this->{bufferedcommand}--;
	}

	$this;
}

sub _sendData {
	my $this = shift;

	my $data = shift;

	my $sock = $this->{sock};

	local($SIG{ALRM});

	$SIG{ALRM} = sub { die __PACKAGE__."#_sendData: data transfer has timed out. (データ送信がタイムアウトしました)\n"; };
	alarm($this->{timeout_period});
	local($\) = '';

	foreach my $line (split(/\r?\n/, $data)) {
		$line =~ s/^\./../;
		$this->_log("send>> $line");

		$line .= "\r\n";
		print $sock $line;
		alarm($this->{timeout_period});
	}

	$this->_log("send>> .");
	print $sock ".\r\n";
	alarm(0);

	$this->_waitReply;

	$this;
}

sub _waitReply {
	my $this = shift;
	my $sock = $this->{sock};

	local($SIG{ALRM});

	$SIG{ALRM} = sub { die __PACKAGE__."#_waitReply: waiting for reply has timed out. (応答待ちでタイムアウトしました)\n"; };
	alarm($this->{timeout_period});

	my $line;
	delete $this->{status};
	while($line = <$sock>) {
		alarm($this->{timeout_period});
		$line =~ tr/\r\n//d;
		$this->_log("recv<< [$line]");
		if($line =~ m/^(\d+)([\- ])?(.*)/) {
			$this->{status}{resultcode} = $1;
			$this->{status}{resultmessage} .= "$3\n";
			last if($2 ne '-');
		}
	}

	alarm(0);

	$this;
}

sub _waitReplyAll {
	my $this = shift;
	my $sock = $this->{sock};

	$this->_log("[waitReplyAll]");

	$this->{bufferedcommand}--;

	while($this->{bufferedcommand} > 0) {
		$this->{bufferedcommand}--;
		$this->_waitReply;
	}

	$this;
}

sub _getResultCode {
	# 最後に受け取ったリザルトコードを返す。
	my $this = shift;

	$this->{status}{resultcode};
}

__END__

=encoding utf-8

=for stopwords
	YMIRLINK
	setTimeout
	ini
	Ini

=head1 NAME

Tripletail::Sendmail::Smtp - SMTP メール送信

=head1 DESCRIPTION

指定されたsmtpサーバーに向けてメールを送信する。

送信先ドメインのMXレコードを引いて直接送信するのではない。

=head2 METHODS

=over 4

=item new

=item disconnect

=item send

L<Tripletail::Sendmail> 参照。

=item setTimeout

  $smail->setTimeout($timeoutsec)

タイムアウトまでの秒数を設定する。

=item connect

  $smail->connect($host)

メール送信先に接続を行い、sendメソッドの準備を整える。

$host が指定されなかった場合は、 ini ファイルの設定が使用される。
ini ファイルにも設定がない場合は、 localhost となる。


=back


=head2 Ini パラメータ

=over 4

=item timeout

  timeout = 1 min

タイムアウト秒数。L<度量衡|Tripletail/"度量衡"> 参照。省略可能。
デフォルトは C<300 sec>。

=item host

  host = localhost

接続先ホスト。省略可能。
デフォルトは localhost 。

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
