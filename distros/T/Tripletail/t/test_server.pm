## ----------------------------------------------------------------------------
#  t/test_server.pm
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright YMIRLINK, Inc.
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package t::test_server;
use strict;
use warnings;
use Crypt::CBC;
use Crypt::Rijndael;
use Data::Dumper;
use LWP::UserAgent;

our $HTTP_PORT = 8967;
our $SERVER_PID;
our $KEY;
our $UserAgent;
our @cleanup;

END
{
	local($?);
	if( $SERVER_PID )
	{
		&stop_server;

		foreach my $sub (reverse @cleanup)
		{
			$sub->();
		}
	}
}

1;

# -----------------------------------------------------------------------------
# add_cleanup(\&sub);
#  add cleanup routine.
#
sub add_cleanup
{
	push(@cleanup, shift);
}

# -----------------------------------------------------------------------------
# check_requires.
#  returns message for skip_all.
#  or '' on all green.
#
sub check_requires() {
    local($SIG{__DIE__}) = 'DEFAULT';

    eval {
        require POE;
        require POE::Component::Server::HTTP;
    };
    if ($@) {
        return "PoCo::Server::HTTP is required for these tests...";
    }

    eval {
        require HTTP::Cookies;
    };
    if ($@) {
        return "HTTP::Cookies is required for these tests...";
    }

    eval {
        require HTTP::Status;
        import HTTP::Status;
    };
    if ($@) {
        return "HTTP::Status is required for these tests...";
    }

    eval {
        require URI::QueryParam;
    };
    if ($@) {
        return "URI::QueryParam is required for these tests...";
    }

    eval {
        use IO::Socket::INET;
        my $sock = IO::Socket::INET->new(
            LocalPort => $HTTP_PORT,
            Proto => 'tcp',
            Listen => 1,
            ReuseAddr => 1,
           );
        $sock or die;
    };
    if ($@) {
        return "port $HTTP_PORT/tcp required not to be in use for these tests...";
    }

    return;
}

# -----------------------------------------------------------------------------
# start server.
#  returns key for encryption.
#
sub start_server ()
{
	# 子プロセスでPoCo::Server::HTTPを立てる。
	
	# 通信混入防止の暗号化キー.
	$KEY = '';
	for (1 .. 10) {
		$KEY .= int(rand 0xffffffff);
	}
	
	# UserAgent の生成.
	$UserAgent = LWP::UserAgent->new;
	my $cookie_jar = HTTP::Cookies->new;
	$UserAgent->cookie_jar($cookie_jar);
	
	# プロセス分岐.
	$SERVER_PID = fork();
	if( $SERVER_PID )
	{
		# parent.
		# サーバーが起動するまで1秒待つ
		#diag("Waiting 1 sec for the coming of server... [pid:$SERVER_PID]");
		sleep 1;
		
		return $KEY;
	}
	
	# child.
	my $heap = {
		script => undef,
		ini    => undef,
		stdin  => undef,
		env    => undef,
	};
	
	POE::Component::Server::HTTP->new(
		Port => $HTTP_PORT,
		ContentHandler => {
			'/install' => sub{ &_prepare_script($heap, @_); },
			'/'        => sub{ &_run_script($heap, @_); },
		},
	);
	
	POE::Kernel->run();
	exit;
}

# -----------------------------------------------------------------------------
# /install ハンドラ. 
# 擬似CGI実行用の環境を準備する.
#
sub _prepare_script
{
	my $heap = shift;
	my $req  = shift;
	my $resp = shift;
	my $uri = $req->uri;
	
	# パラメータは関係ない通信が紛れてこないように適当に暗号化
	# されているので, 取り出す時に復号..
	
	my $cipher = _get_cipher();
	
	if (defined($_ = $uri->query_param('ini')))
	{
		if ($_ = $cipher->decrypt($_)) {
			$heap->{ini} = $_;
		}
	}
	
	if (defined($_ = $uri->query_param('stdin'))) {
		if ($_ = $cipher->decrypt($_)) {
			$heap->{stdin} = $_;
		}
	}
	
	if (defined($_ = $uri->query_param('script'))) {
		if ($_ = $cipher->decrypt($_)) {
			$heap->{script} = $_;
		}
	}
	
	if (defined($_ = $uri->query_param('env'))) {
		$heap->{env} = eval $cipher->decrypt($_);
	}
	
	$resp->code(204);
	$resp->message(status_message($resp->code));
	return 204;
}

# -----------------------------------------------------------------------------
# / ハンドラ.
# /installで設定した擬似CGIを実行する.
#
sub _run_script
{
	my $heap = shift;
	my $req  = shift;
	my $resp = shift;

	my $inifile = -d 't' ? "t/tmp$$.ini" : "tmp$$.ini";
	my $script  = "use Tripletail qw($inifile);\n" . $heap->{script};
	do {
		open my $fh, '>', $inifile;
		if ($heap->{ini}) {
			print $fh $heap->{ini};
		}
	};

	# その子プロセスでスクリプトをevalする。

	pipe my $p_read, my $c_write;
	pipe my $c_read, my $p_write;
	my $received_data = '';
	if (fork) {
		# parent.
		close $c_write;
		close $c_read;
		if (defined $heap->{stdin}) {
			print $p_write $heap->{stdin};
		}
		close $p_write;

		while (defined($_ = <$p_read>)) {
			$received_data .= $_;
		}

		wait;
	} else {
		# child.
		close $p_read;
		close $p_write;

		open STDIN,  '<&' . fileno $c_read;
		open STDOUT, '>&' . fileno $c_write;

		if ($heap->{env}) {
			while (my ($key, $val) = each %{$heap->{env}}) {
				$ENV{$key} = $val;
			}
		}

		$ENV{REQUEST_URI} = '/';
		$ENV{SERVER_NAME} = 'localhost';
		$ENV{REQUEST_METHOD} = $req->method;
		$ENV{CONTENT_TYPE} = defined $req->header('Content-Type') ?
			$req->header('Content-Type') : 'application/x-www-form-urlencoded';
		$ENV{CONTENT_LENGTH} = defined $heap->{stdin} ? length($heap->{stdin}) : 0;

		if ($_ = $req->header('Cookie')) {
			$ENV{HTTP_COOKIE} = $_;
		} else {
			delete $ENV{HTTP_COOKIE};
		}

		eval $script;
		$@ and print "Status: 599\r\nX-Internal-Error: 1\r\n\r\n$@";
		exit;
	}

	unlink $inifile;

	# 結果をHTTPからパースしてhttpdへ渡す。

	my $msg = HTTP::Message->parse($received_data);
	my $retval = do {
		my $st = $msg->headers->header('Status');
		if (defined $st) {
			$st =~ m/^(\d+)/;
			$1;
		}
		else {
			200;
		}
	};
	$resp->code($retval);
	$resp->message(status_message($resp->code));

	if (defined &HTTP::Headers::header_field_names) {
		foreach my $key ($msg->headers->header_field_names) {
			$resp->headers->header(
				$key => $msg->headers->header($key));
		}
	}
	else {
		foreach my $key (keys %{ $msg->headers }) {
			# Workaround for old HTTP::Headers. !! UNSAFE !!
			$resp->headers->header(
				$key => $msg->headers->header($key));
		}
	}

	$resp->content($msg->content);
	return $retval;
}

# -----------------------------------------------------------------------------
# stop server.
#
sub stop_server ()
{
	if( $SERVER_PID )
	{
		#diag("Waiting for the going of server... [pid:$SERVER_PID]");
		
		kill 9, $SERVER_PID;
		wait;
		
		$SERVER_PID = undef;
	}
}

# -----------------------------------------------------------------------------
# request(%opts);
# request_get(%opts);
# request_post(%opts);
#  ini     => $ini, or \%ini.
#  script  => $code.
#  stdin   => $stdin.
#  env     => $env.
#  request => 'GET','POST' (required)
#  db      => $db,\@db
#  session => $sess,\@sess
#  cleanup => \&cleanup.
#
#  コード片を startCgi の main で実行してその復帰値を返す. 
#  指定しなかったパラメータは前のが残る(子プロセスで消してないから).
# 
sub request_get (@){ request(@_, method=>'GET' );  }
sub request_post(@){ request(@_, method=>'POST' ); }
sub request
{
	my $code = @_%2 ? shift : undef;
	my $opts = {@_};
	defined($code) and $opts->{script} = $code;
	
	# 実行するコードを文字列で引数から.
	my $code_str = $opts->{script};
	
	# DB と Session. 渡された時だけパラメータ生成. 
	my $dumper = sub{
		my ($key, $val) = @_;
		my $text = Data::Dumper->new([$val])->Terse(1)->Indent(0)->Dump;
		$text = "$key => $text,";
		$val or $text = "#$text";
		$text;
	};
	my $db_spec = $dumper->(-DB => $opts->{db});
	my $sess_spec = $dumper->(-Session => $opts->{session});
	
	# サーバ側ではそれを-mainで実行して Data::Dumper で固めて返す. 
	my $tmpl = q{
		use strict;
		use warnings;
		use Data::Dumper;
		$TL->startCgi(
			<&DB>
			<&SESSION>
			-main    => sub{
				my $ret = _main();
				my $dd = Data::Dumper->new([$ret]);
				$dd->Purity(1);
				$dd->Useqq(1);
				$dd->Terse(1);
				$TL->print( 'REPLYMARK'.$dd->Dump() );
				#$TL->print( 'REPLYMARK'.t::test_server::_get_cipher()->encrypt($dd->Dump()) );
			},
		);
		sub _main {
			<&CODE>
		}
	};
	
	my $script = $tmpl;
	$script =~ s/<&CODE>/$code_str/;
	$script =~ s/<&DB>/$db_spec/;
	$script =~ s/<&SESSION>/$sess_spec/;
	#print STDERR $script;
	
	# サーバ側に転送＆実行.
	my $res = raw_request(
		%$opts,
		script => $script,
	);
	# 結果は Data::Dumper で固めてあるので展開する.
	# 一応頭のマークをチェック.
	my $pack = $res->content;
	if( $pack !~ s/^REPLYMARK// )
	{
		my $internal_error = "\xe5\x86\x85\xe9\x83\xa8".
		                     "\xe3\x82\xa8\xe3\x83\xa9\xe3\x83\xbc";
		my $re_internal_error = qr{<title>\[TL\] $internal_error</title>};
		my $re_pick_message = qr{<p class="message">\s*(.*?)\s*</p>}s;
		if( $pack =~ $re_internal_error && $pack =~ $re_pick_message )
		{
			my $msg = $1;
			$msg =~ s/&#39;/\x27/g; # single quote.
			$msg =~ s/&gt;/>/g;
			die "$msg\n";
		}
		die "invalid data: [$pack]";
	}
	#my $decrypted = _get_cipher()->decrypt($pack);
	my $decrypted = $pack;
	$decrypted = $decrypted=~/^(.*)\z/s && $1 or die "untaint";
	my $data = eval $decrypted;
	$@ and die "parsing result failed: $@ ";
	
	# 展開した結果を返す.
	$data;
}

# -----------------------------------------------------------------------------
# raw_request(%opts);
#  ini    => $ini, or \%ini.
#  script => $code.
#  stdin  => $stdin.
#  env    => $env.
#  method => 'GET','POST' (required)
#  params => \%params,\@params, to user-agent get/post request.
#  cleanup => \&cleanup.
#
#  script で渡したコードをそのまま実行する.
#  指定しなかったパラメータは前のが残る(子プロセスで消してないから).
#
sub raw_request
{
	my $opts = { @_ };
	my $ini = $opts->{ini};
	my $script = $opts->{script};
	my $env = $opts->{env};
	my $stdin = $opts->{stdin};
	my $meth = $opts->{method};
	if( !$meth || $meth !~/^(GET|POST)\z/ )
	{
		die "method is required at request";
	}
	
	my $cipher = _get_cipher();
	
	if( ref($ini) )
	{
		my $text = '';
		foreach my $group (sort keys %$ini)
		{
			$text .= "[$group]\n";
			foreach my $key (sort keys %{$ini->{$group}})
			{
				my $val = $ini->{$group}{$key};
				!defined($val) and next;
				ref($val) eq 'ARRAY' and $val = join(',',@$val);
				$text .= "$key = $val\n";
			}
		}
		$ini = $text;
	}
	
	# 関係ない通信が紛れてこないように適当に暗号化.
	my $uri = URI->new("http://localhost:$HTTP_PORT/install");
	$uri->query_param(ini    => $cipher->encrypt(defined $ini ? $ini : ''));
	$uri->query_param(script => $cipher->encrypt(defined $script ? $script : ''));
	$uri->query_param(stdin  => $cipher->encrypt(defined $stdin ? $stdin : ''));
	if ($env) {
		$uri->query_param(
				env => $cipher->encrypt(
					Data::Dumper->new([$env])
					->Purity(1)->Useqq(1)->Terse(1)->Dump));
	}
	
	# サーバ側に転送.
	my $res = $UserAgent->get($uri); # HTTP::Response.
	if( !$res->is_success )
	{
		die $res->as_string;
	}
	
	# サーバ側で実行.
	$meth = lc($meth);
	my $params = $opts->{params} || [];
	ref($params) eq 'HASH' and $params = [%$params];
	$res = $UserAgent->$meth("http://localhost:$HTTP_PORT/", @$params);
	
	if( $opts->{cleanup} )
	{
		local($@);
		eval{ $opts->{cleanup}->() };
		if( my $err = $@ )
		{
			$err =~ s/^(?!\z)/# /mg;
			print STDERR $err;
		}
	}
	
	$res;
}

sub _get_cipher
{
	# Rijndael requires untainted salt.
	my $salt = Crypt::CBC->can('_get_random_bytes') && Crypt::CBC->_get_random_bytes(8)=~/^(.*)\z/s && $1;
	my $cipher = Crypt::CBC->new({
		key    => $KEY,
		cipher => 'Rijndael',
		salt   => $salt,
	});
	$cipher;
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
