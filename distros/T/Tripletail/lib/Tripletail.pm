# -----------------------------------------------------------------------------
# TL - Tripletailメインクラス
# -----------------------------------------------------------------------------
# $Id$
package Tripletail;
use strict;
use warnings;
BEGIN{ our $_CHKNONLAZY=$ENV{PERL_DL_NONLAZY} }
BEGIN{ our $_CHKDYNALDR=$INC{'DynaLoader.pm'} }
use File::Spec;
use Data::Dumper;
use List::MoreUtils qw(any);
use POSIX qw(:errno_h);
use Scalar::Util qw(blessed);
use Cwd ();

our $VERSION = '0.50';
our $XS_VERSION = $VERSION;
$VERSION = CORE::eval $VERSION;

our $TL = Tripletail->__new;
our @specialization;
our $LOG_SERIAL = 0;
our $LASTERROR;
our %_FILE_CACHE;
my $_FILE_CACHE_MAXSIZE = 10_1024*1024;
my $_FILE_CACHE_CURSIZE = 150; # variables for caching.
our $CWD;
our $IS_FCGI_WIN32;
our $FCGI_LOADMSG_WIN32;

# 動的スコープにより startCgi 内部である事を表す。
# 他のパッケージからも参照されるので削除してはならない。
our $IN_EXTENT_OF_STARTCGI;

if ($ENV{TL_COVER_TEST_MODE}) {
    CORE::eval {
        require Devel::Cover;
        Devel::Cover->import(
            -silent   => 'on',
            -summary  => 'off',
            -db       => './cover_db',
            -coverage => (
                'statement', 'branch', 'condition', 'path', 'subroutine', 'time'
               ),
            '+ignore' => '^/'
           );
    };
    if ($@) {
        die "Failed to load Devel::Cover: $@";
    }
}

*errorTrap = \&_errorTrap_is_deprecated;
sub _errorTrap_is_deprecated {
    die "\$TL->errorTrap(..) is deprecated, use \$TL->trapEror(..)"
}

if ($ENV{MOD_PERL}) {
    CORE::eval {
        require Apache2::RequestRec;
        require Apache2::RequestIO;
        require Apache2::RequestUtil;
        require Apache2::Const;
        Apache2::Const->import(-compile => qw(OK));
    };
    if ($@) {
        local $SIG{__DIE__} = 'DEFAULT';
        die "Failed to load modules to work with mod_perl: $@";
    }
}

1;

# -----------------------------------------------------------------------------
# ロード時初期化
# -----------------------------------------------------------------------------
sub import {
    my $class  = shift;
    my $caller = (caller(0))[0];

    no strict qw(refs);
    *{"${caller}::TL"} = *{"Tripletail::TL"};

    if (defined $TL->{INI}) {
        if (exists $_[0]) {
            die "use Tripletail: ini file has been already loaded." .
              " (iniファイルを指定した use Tripletail は一度しか行えません)\n";
        }
    }
    else {
        my $ini_file = do {
            if (exists $_[0]) {
                $_[0];
            }
            else {
                if (_is_in_pod_coverage() || _is_in_b_perlreq()) {
                    File::Spec->devnull();
                }
                else {
                    die "Usage: \"use Tripletail qw(config.ini);\"".
                      " (use Tripletail の際にiniファイルの指定が必要です)\n";
                }
            }
        };

        if ($ini_file eq File::Spec->devnull()) {
            $TL->{INI} = $TL->newIni();
        }
        else {
            $TL->{INI} = $TL->newIni($ini_file);
        }
        $TL->{INI}->const;

        if (defined($_[0])) {
            @specialization = @_;
        }

        $TL->{trap} = $TL->{INI}->get(TL => trap => 'die');
        if (!any { $TL->{trap} eq $_ } qw(none die diewithprint)) {
            die __PACKAGE__."#import: unknown trap mode [$TL->{trap}]".
              " (trapオプションの指定が正しくありません).\n";
        }

        if (any { $TL->{trap} eq $_ } qw(die diewithprint)) {
            $SIG{__DIE__} = \&__die_handler_for_startup;
        }

        # dummy symbol to avoid the false alarm by strict.pm.
        *{"${caller}::CGI"} = _gensym();
    }
    # preload some modules.
    # (workaround for "BEGIN not safe after errors--compilation aborted", perldiag)
    require Tripletail::Error;
    require Tripletail::Debug;
}

sub __die_handler_for_startup
{
	my $msg = shift;
	my $trap = shift || $TL->{trap};

	if( _isa($msg, 'Tripletail::Error') )
	{
		die $msg;
	}
	my $prev = $LASTERROR;
	if( $prev && !ref($msg) && $msg =~ s/^\Q$prev\E(?=Compilation failed in require at )// )
	{
		$prev->{message} .= $msg;
		die $prev;
	}

	my $err = $TL->newError(error => $msg);
	$LASTERROR = $err;

	if( $trap eq 'diewithprint' && $err->{appear} ne 'usertrap' )
	{
		# die-with-print時かつevalの外であれば,
		# エラーをヘッダと共に表示する.
		$TL->__dispError($err);
	}elsif( $err->{appear} eq 'sudden' && $TL->_getRunMode eq 'CGI' && !$^S )
	{
		# Internal Server Error.
		# 詳細なエラー内容がでても微妙なことがあるので軽いメッセージにしておく.
		# でも Status: 500 は ErrorDocument 500 に反応しなくなるようなので,
		# 一応compatも入れておく.
		$err->{message} = "Internal Error has occured. To display details, you should set [TL] trap=diewithprint on ini file. (内部エラーが発生しました. 詳細を表示するには ini ファイルに [TL] trap=diewithprint の設定を加えてください)";
		if( !$TL->INI->get(TL => compat_no_trap_for_cgi_internal_error => 0) )
		{
			$TL->__dispError($err);
		}
	}

	die $err;
}

# -----------------------------------------------------------------------------
# Pod::Coverage 内からロードされているかの判定.
#  (Test::Pod::Cover 用)
# -----------------------------------------------------------------------------
sub _is_in_pod_coverage {
    if (exists $INC{"Pod/Coverage.pm"}) {
        my $i = 0;
        while (my $pkg = caller(++$i)) {
            return 1 if $pkg eq 'Pod::Coverage';
        }
    }
    return;
}

# -----------------------------------------------------------------------------
# B::PerlReq 内からロードされているかの判定.
#  (Test::Dependencies 用)
# -----------------------------------------------------------------------------
sub _is_in_b_perlreq {
    if (exists $INC{"B/PerlReq.pm"}) {
        return 1;
    }
    else {
        return;
    }
}

# -----------------------------------------------------------------------------
# 生成
# -----------------------------------------------------------------------------
sub __new {
	my $pkg = shift;
	my $this = bless {} => $pkg;

	$this->{INI} = undef; # Tripletail::Ini
	$this->{CGI} = undef; # Tripletail::Form。preRequest直前に生成され、postRequest後に消される。
	$this->{CGIORIG} = undef; # Tripletail::Form。preRequest直前に生成され、postRequest後に消される。

	$this->{trap} = 'die'; # 'none' | 'die' | 'diewithprint'

	$this->{filter} = {}; # 優先順位 => Tripletail::Filter
	$this->{filterlist} = []; # [Tripletail::Filter, ...] 優先順位でソート済み

	$this->{saved_filter} = {}; # $this->{filter} のコピー

	$this->{inputfilter} = {}; # 優先順位 => Tripletail::InputFilter
	$this->{inputfilterlist} = []; # [Tripletail::InputFilter, ...] 優先順位でソート済み

	$this->{hook} = {
		init        => {}, # 優先順位 => CODE
		term        => {},
		initRequest => {},
		preRequest  => {},
		postRequest => {},
	};
	$this->{hooklist} = {
		init        => [], # [CODE, ...] 優先順位でソート済み
		term        => [],
		initRequest => [],
		preRequest  => [],
		postRequest => [],
	};

	$this->{encode_is_available} = undef; # undef: 不明  0: Encode利用不可  1: Encode利用可

    $this->{ fcgi_request} = undef; # FCGI または undef

	$this->{script_name} = undef; # プログラム名

	$this;
}

sub DESTROY {
	my $this = shift;
	$SIG{__DIE__} = 'DEFAULT';
	if(exists($this->{cacheLogFh})) {
		close($this->{cacheLogFh});
	}
}

sub CGI {
	my $this = shift;
	$this->{CGI};
}

sub INI {
	my $this = shift;
	$this->{INI};
}

sub fork {
    my $this = shift;

    if ($this->{fcgi_request}) {
        $this->{fcgi_request}->Detach;
    }

    my $pid = CORE::fork();

    if (not defined $pid) {
        die "TL#fork: failed: $!";
    }
    elsif ($pid == 0) {
        # child

        if ($this->{fcgi_request}) {
            # 何故か FCGI::DESTROY を殺して置かないと、子プロセスの方が早く死んだ
            # 時に Internal Server Error になってしまう。Detach しているのだから
            # DESTROY がソケットを弄るのはおかしいのだが、現実としてそうなってい
            # る。
            # http://wiki.dreamhost.com/Perl_FastCGI
            *FCGI::DESTROY = sub {};
        }

        require Tripletail::DB;

        Tripletail::DB::_reconnectSilentlyAll();
    }
    else {
        # parent
        if ($this->{fcgi_request}) {
            $this->{fcgi_request}->Attach;
        }
    }

    return $pid;
}

sub eval {
    my $this = shift;
    my $sub  = shift;

    local $SIG{__DIE__} = 'DEFAULT';
    return CORE::eval { $sub->() };
}

sub escapeTag {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#escapeTag: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/\&/\&amp;/g;
	$str =~ s/</\&lt;/g;
	$str =~ s/>/\&gt;/g;
	$str =~ s/\"/\&quot;/g;
	$str =~ s/\'/\&#39;/g;

	$str;
}

sub unescapeTag {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#unescapeTag: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/\&lt;/</g;
	$str =~ s/\&gt;/>/g;
	$str =~ s/\&quot;/\"/g;
	$str =~ s/\&apos;/\'/g;
	$str =~ s!(\&(?:(amp)|#(\d+)|#x([0-9a-fA-F]+));)!
		if( $2 ) {
			'&';
		} elsif ( defined($3) && $3 ne '' ) {
			$3>=0x20 && $3<=0x7e ? pack("C",$3) : $1;
		} else { 
			hex($4)>=0x20 && hex($4)<=0x7e ? pack("C",hex($4)) : $1;
		}!ge;

	$str;
}

our $JSSTRING_SPLIT_RE = sub {
	# </script と --> を分割する為の正規表現
	# 要は、"111</script>222-->333"のような文字列をsplitすると、
	# [ "111</scr", "ipt>222-", "->333" ]
	# のように分割されるような正規表現を用意する
	# (これは最終的には'"111</scr"+"ipt>222-"+"->333"'のように加工される)
	# TODO: もう少し緩い判定にすべきかも知れない
	#       (「< / script>」等が有り得る？)
	my $scr = quotemeta('</scr');
	my $ipt = quotemeta('ipt');
	my $comment_end1 = quotemeta('-');
	my $comment_end2 = quotemeta('->');
	qr/(?:(?<=${scr})(?=${ipt}))|(?:(?<=${comment_end1})(?=${comment_end2}))/i;
}->();

sub escapeJsString {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#escapeJsString: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	my $splitted = [ split($JSSTRING_SPLIT_RE, $str) ];
	# 分割した文字列をJavaScriptの'"</scr"+"ipt>"'状態にする
	my $result = join('"+"', (map { $this->escapeJs($_) } grep { defined } (@$splitted)));
	'"' . $result . '"';
}

sub unescapeJsString {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#unescapeJsString: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	die "TL#unescapeJsString: arg[1] is not JsString. (第1引数がJsString形式になっていません)\n" if not ($str =~ /^['"](.*)['"]$/);
	my $body = $1;
	$body =~ s/(?:\"\+\")|(?:\'\+\')//g;
	$this->unescapeJs($body);

	$body;
}
sub escapeJs {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#escapeJs: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/(['"\\])/\\$1/g;
	$str =~ s/\r/\\r/g;
	$str =~ s/\n/\\n/g;
	$str =~ s/</\\x3c/g;
	$str =~ s/>/\\x3e/g;

	$str;
}

sub unescapeJs {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#unescapeJs: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	my $map = {
	  'r' => "\r",
	  'n' => "\n",
	  "'" => "'",
	  '"' => '"',
	  "\\" => "\\",
	  "x3c" => "<",
	  "x3e" => ">",
	};
	$str = "$str"; # stringify.
	$str =~ s/\\([rn'"\\]|x3[ce])/$map->{$1}/ge;

	$str;
}

sub encodeURL {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#encodeURL: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/([^a-zA-Z0-9\-\_\.\!\~\*\'\(\)])/
	'%' . sprintf('%02x', unpack("C", $1))/eg;

	$str;
}

sub decodeURL {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#decodeURL: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/\%([a-zA-Z0-9]{2})/pack("C", hex($1))/eg;

	$str;
}

sub escapeSqlLike {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#escapeSqlLike: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/\\/\\\\/g;
	$str =~ s/\%/\\\%/g;
	$str =~ s/\_/\\\_/g;

	$str;
}

sub unescapeSqlLike {
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die "TL#unescapeSqlLike: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = "$str"; # stringify.
	$str =~ s/\\\%/\%/g;
	$str =~ s/\\\_/\_/g;
	$str =~ s/\\\\/\\/g;

	$str;
}

sub __die_handler_for_localeval
{
	# スタックトレースを付け加えて再度dieする。
	# それ以外の事はしない。
	my $msg = shift;

	die _isa($msg, 'Tripletail::Error') ? $msg : $TL->newError(error => $msg);
}

sub startCgi {
	my $this = shift;
	my $param = { @_ };

    local $IN_EXTENT_OF_STARTCGI = 1;
	$this->{script_name} = $0;

	$this->_clearCwd();
	$this->{outputbuffering} = $this->INI->get(TL => 'outputbuffering', 0);

	my $main_err;
	CORE::eval {
		# trap = diewithprint の場合はエラーハンドラを付け替える
		# そうしないと Content-Type: text/plain が出力されてしまう。
		if($this->{trap} eq 'diewithprint') {
			$SIG{__DIE__} = \&__die_handler_for_localeval;
		}

		# Tripletail::Debugをロード。debug機能が有効になっていれば、
		# ここで各種フック類がインストールされる。
		$this->getDebug;

		if(defined(my $group = $param->{-DB})) {
			require Tripletail::DB;

			if(!ref($group)) {
				Tripletail::DB->_connect([$group]);
			} elsif (ref($group) eq 'ARRAY') {
				Tripletail::DB->_connect($group);
			}
		}

		if(!defined($param->{'-main'})) {
			die __PACKAGE__."#startCgi: -main handler is not defined. (-main引数が指定されていません)\n";
		}

		# ここでフィルタ類のデフォルトを設定
		if(!$this->getContentFilter) {
			$this->setContentFilter('Tripletail::Filter::HTML');
		}
		if(!$this->getInputFilter) {
			$this->setInputFilter('Tripletail::InputFilter::HTML');
		}
		if( $ENV{MOD_PERL} )
		{
			my $r = Apache2::RequestUtil->request;
			$TL->{mod_perl} = { request => $r };
		}

		if($this->_getRunMode eq 'FCGI') {
			# FCGIモードならメモリ監視フックとファイル監視フックをインストール
			$this->getMemorySentinel->__install;
			$this->getFileSentinel->__install;
		}


		if($this->_getRunMode eq 'FCGI') {
			# FCGIモード

			my $maxrequestcount = $this->INI->get(TL => 'maxrequestcount', 0);
            if ($this->INI->get(TL => 'fcgilog' => 0)) {
                $this->log(FCGI => 'Starting FCGI Loop... maxrequestcount: ' . $maxrequestcount);
            }
			my $requestcount = 0;

			do {
				local $SIG{__DIE__} = 'DEFAULT';
				#no warnings;
				CORE::eval 'use FCGI';
			};
			if($@) {
				die __PACKAGE__."#startCgi: failed to load FCGI.pm [$@] (FCGI.pmがロードできません)\n";
			}

			my $exit_requested;
			my $handling_request;
			local $SIG{USR1} = sub {
                if ($this->INI->get(TL => 'fcgilog' => 0)) {
                    $this->log("SIGUSR1 received");
                }
				$exit_requested = 1;
			} if( exists($SIG{USR1}) );
			local $SIG{TERM} = sub {
				# NB: FCGIモードでは、fastcgiマネージャから
				#     SIGTERMが送られてくる為、
				#     状況に応じて挙動を変更する(以下を参照)
				# http://d.tir.jp/pw?mod_fastcgi の一番下
				# https://192.168.0.17/mantis/view.php?id=1037
                if ($this->INI->get(TL => 'fcgilog' => 0)) {
                    $this->log("SIGTERM received");
                }
				$exit_requested = 1;
			};
			local $SIG{PIPE} = 'IGNORE';

			{
				#no warnings;
				$this->{fcgi_request} = FCGI::Request(
					\*STDIN, \*STDOUT, \*STDERR, \%ENV,
					0, FCGI::FAIL_ACCEPT_ON_INTR());
			}

			while(1) {
				my $accepted = CORE::eval {
					#no warnings;
					local $SIG{__DIE__} = 'DEFAULT';
					local $SIG{USR1} = sub {
						$exit_requested = 1;
						die("SIGUSR1 received\n");
					} if( exists($SIG{USR1}) );
					local $SIG{TERM} = sub {
						$exit_requested = 1;
						die("SIGTERM received\n");
					};
					$this->{fcgi_request}->Accept() >= 0;
				};
				if($@) {
					if($exit_requested) {
                        if ($this->INI->get(TL => 'fcgilog' => 0)) {
                            $this->log(FCGI => "FCGI_request->Accept() got interrupted : $@");
                        }
						$this->{fcgi_request}->Finish();
						last;
					}else {
						$this->log(FCGI => "FCGI_request->Accept() failed : $@");
						exit 1;
					}
				}

				if(!$accepted) {
					last;
				}

				if( $requestcount==0 )
				{
					# 最初のリクエスト受信時でプロセスの初期化.
					if(defined(my $groups = $param->{-Session})) {
						require Tripletail::Session;

						Tripletail::Session->_init($groups);
					}
					$this->__executeHook('init');
				}
				$this->_update_processname('fcgi run');
				
				$this->__executeCgi($param->{-main});
				$main_err = $@;
				$this->_update_processname('fcgi wait');

				{
					#no warnings;
					$this->{fcgi_request}->Flush;
				}

				$requestcount++;

				if($exit_requested || ($maxrequestcount && ($requestcount >= $maxrequestcount))) {
					last;
				}
				$this->{fcgi_restart} and last;
			}
			{
				#no warnings;
				$this->{fcgi_request}->Finish;
			}
            $this->{fcgi_request} = undef;

            if ($this->INI->get(TL => 'fcgilog' => 0)) {
                $this->log(FCGI => "FCGI Loop is terminated ($requestcount reqs processed).");
            }
		} else {
			# CGIモード
            if ($this->INI->get(TL => 'fcgilog' => 0)) {
                $this->log(TL => 'CGI mode');
            }
			
			# プロセスの初期化.
			if(defined(my $groups = $param->{-Session})) {
				require Tripletail::Session;

				Tripletail::Session->_init($groups);
			}
			$this->__executeHook('init');

			$this->__executeCgi($param->{-main});
			$main_err = $@;
		}

		$this->__executeHook('term');
	};
	if(my $err = $@) {
		if ($this->{trap} eq 'none') {
			die $err;
		}

		if (_isa($err, 'Tripletail::Error') and $err->type eq 'error') {
			$err->message(
				"Died outside the `-main':\n" . $err->message);
		}

		$this->_sendErrorIfNeeded($err);
        $this->_call_fault_handler($err);
	}
	!$@ && $main_err and $@ = $main_err;

	if( $ENV{MOD_PERL} )
	{
		Apache2::Const->OK;
	}else
	{
		$this;
	}
}

sub _update_processname
{
	my $this = shift;
	my $command = shift;
	
	if($this->INI->get(TL => command_add_processname => 1))
	{
	#	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	#	my $timestr = sprintf('%02d:%02d:%02d', $mon + 1, $mday, $hour, $min, $sec);
		my $serial = sprintf('%06d', $LOG_SERIAL % 1000000);
		
		$0 = "perl $serial ($command) " . (defined($this->{script_name}) ? $this->{script_name} : '');
	}
	
}

sub _call_fault_handler
{
	my $this = shift;
	my $err  = shift;
	
	my $printed;
	FAULT_HANDLER:
	{
		my $handler_name = $this->INI->get(TL => 'fault_handler' => undef);
		$handler_name or last FAULT_HANDLER;
		
		my ($modname, $subname) = $handler_name =~ /^(?:::)?(?:(\w+(?:::\w+)*)::)?(\w+)$/;
		if( !defined($subname) )
		{
			$TL->log("fault_handler: invalid name [$handler_name]");
			last FAULT_HANDLER;
		}
		$modname ||= 'main';
		my $sub = $modname->can($subname);
		if( !$sub )
		{
			# load module.
			(my $pmname = $modname.'.pm') =~ s{::}{/}g;
			if( !$INC{$pmname} )
			{
				local($@);
				CORE::eval "require $modname; 1;";
				if( $@ )
				{
					$TL->log("fault_handler: failed to load module [$modname]: $@");
					last FAULT_HANDLER;
				}
			}
			$sub = $modname->can($subname);
			if( !$sub )
			{
				$TL->log("fault_handler: no such subroutine [$subname] in [$modname]");
				last FAULT_HANDLER;
			}
		}
		if( !defined(&$sub) )
		{
			$TL->log("fault_handler: subroutine [$subname] in [$modname] is undefined");
			last FAULT_HANDLER;
		}
		
		local($@);
		CORE::eval{
			$modname->$sub($err);
		};
		if( $@ )
		{
			$TL->log("fault_handler: subroutine [$subname] in [$modname] threw an error: $@");
			last FAULT_HANDLER;
		}
		$printed = 1;
	}
	
	if( !$printed )
	{
		$this->__dispError($err);
	}
	return;
}

sub _fcgi_restart
{
	my $this = shift;
	@_ and $this->{fcgi_restart} = shift;
	$this->{fcgi_restart};
} 

sub trapError {
	my $this = shift;
	my $param = { @_ };

	my $main_err;
	CORE::eval {
		# trap = diewithprint の場合はエラーハンドラを付け替える
		# そうしないと Content-Type: text/plain が出力されてしまう。
		local($SIG{__DIE__}) = 'DEFAULT';
		if ($this->{trap} eq 'diewithprint'){
			$SIG{__DIE__} = \&__die_handler_for_localeval;
		}
		# Tripletail::Debugをロード。debug機能が有効になっていれば、
		# ここで各種フック類がインストールされる。
		$this->getDebug;

		if(defined(my $group = $param->{-DB})) {
			require Tripletail::DB;

			if(!ref($group)) {
				Tripletail::DB->_connect([$group]);
			} elsif(ref($group) eq 'ARRAY') {
				Tripletail::DB->_connect($group);
			}
		}

		if(!defined($param->{'-main'})) {
			die __PACKAGE__."#trapError: -main handler is not defined. (-main引数が指定されていません)\n";
		}

		$this->__executeHook('init');
		$this->__executeHook('initRequest');
		$this->__executeHook('preRequest');
		$this->_saveContentFilter;

		CORE::eval {
			$param->{'-main'}();
		};
		$main_err = $@;
		if(my $err = $@) {
			if($this->{trap} eq 'none') {
				die $err;
			}

			$this->_sendErrorIfNeeded($err);
			print STDERR $err;
			
			my $errorlog = $this->INI->get(TL => errorlog => 1);
			if($errorlog > 0) {
				$this->log(__PACKAGE__, "$err");
			}
		}

		$this->_restoreContentFilter;
		$this->__executeHook('postRequest');
		$this->__executeHook('term');
	};
	if(my $err = $@) {
		if ($this->{trap} eq 'none'){
			die $err;
		}

		# このevalでキャッチされたという事は、-mainの外で例外が起きた。
		$this->log(trapError => "Died outside the `-main': $err");
		print STDERR __PACKAGE__."#trapError: died outside the `-main': $err (main関数の外側でdieしました)\n";
	}
	!$@ && $main_err and $@ = $main_err;

	$this;
}

sub dispatch {
	my $this = shift;
	my $name = shift;
	my $param = { @_ };

	if(!defined($name)) {
		if(!defined($param->{'default'})) {
			die __PACKAGE__."#dispatch： arg[1] is not defined but no default value is specified. (第1引数もdefaultも指定されていません)\n";
		} elsif(ref($param->{'default'})) {
			die __PACKAGE__."#dispatch: the default value is a reference [$param->{'default'}]. (default指定がリファレンスです)\n";
		} else {
			$name = $param->{'default'};
		}
	} elsif(ref($name)) {
		die __PACKAGE__."#dispatch: arg[1] is a reference. [$name] (第1引数がリファレンスです)\n";
	} elsif( $name !~ /^[A-Z]/ ) {
		if(!defined($param->{'onerror'})) {
			die __PACKAGE__."#dispatch: arg[1] must start with upper case character. (第1引数は大文字から始まる必要があります)\n";
		} else {
			CORE::eval {
				$param->{'onerror'}();
			};
			if($@) {
				die __PACKAGE__."#dispatch: onerror handler threw an error. [$@] (onerrorの関数でエラーが発生しました)\n";
			}
			return;
		}
	}

	my $args = $param->{args} || [];
	if( !_isa($args, 'ARRAY') )
	{
		die __PACKAGE__."#dispatch： arg{args} is not array-ref. (args 引数がarray-refではありません)\n";
	}

	# 呼ばれる関数のあるパッケージはcallerから得る。
	my $pkg = caller;
	my $func = $pkg->can("Do$name");

	if($func && defined(&$func)) {
		$this->_update_processname("Do$name");
		$func->(@$args);
		1;
	} else {
		if(!defined($param->{'onerror'})) {
			undef;
		} else {
			CORE::eval {
				$param->{'onerror'}();
			};
			if($@) {
				die __PACKAGE__."#dispatch: onerror handler threw an error. [$@] (onerrorの関数でエラーが発生しました)\n";
			}
		}
	}
}

sub log {
	my $this = shift;
    my $group;
    my $message;

    my $stringify = sub {
        my $val = shift;

        if (ref $val) {
            Data::Dumper->new([$val])
              ->Indent(1)->Purity(0)->Useqq(1)->Terse(1)->Deepcopy(1)
                ->Quotekeys(0)->Sortkeys(1)->Deparse(1)->Dump;
        }
        else {
            $val; # 元々スカラーだった
        }
    };

    if (@_ == 1) {
        # "呼出し元ファイル名(行数):関数名"
        my ($filename, $line) = (caller 0)[1, 2];
        my $sub = (caller 1)[3];
        defined($sub) or $sub = '(nosub)';

        $group   = sprintf '%s(%d) >> %s', $filename, $line, $sub;
        $message = $stringify->(shift);
    }
    elsif (@_ == 2) {
        $group   = shift;
        $message = $stringify->(shift);
    }
    else {
        die "TL#log: invalid call of \$TL->log(). (引数の数が正しくありません)\n";
    }

    if(!defined($group)) {
        die "TL#log: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    if(!defined($message)) {
        die "TL#log: arg[2] is not defined. (第2引数が指定されていません)\n";
    }

    $this->getDebug->_tlLog(
        group => $group,
        log   => $message,
    );

    $this->_log($group, $message);
}

sub _log {
	my $this = shift;
	my $group = shift;
	my $log = shift;

	if(!defined($group)) {
		die "TL#_log: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	if(!defined($log)) {
		die "TL#_log: arg[2] is not defined. (第2引数が指定されていません)\n";
	}

	my $time = time;
	my @localtime = localtime($time);
	$localtime[4]++;
	$localtime[5] += 1900;

	$log = sprintf('== %02d:%02d:%02d(%08x) %04x %04x [%s]',
		@localtime[2,1,0], $time, $$, ($LOG_SERIAL % 0x10000), $group)
		. "\n" . $log . "\n";

	if(!exists($this->{logdir})) {
		$this->{logdir} = $this->INI->get_reloc(TL => 'logdir' => undef);
		if( defined($this->{logdir}) )
		{
			# trust TL.logdir parameter.
			$this->{logdir} = $this->{logdir}=~/^(.*)\z/ && $1 or die "untaint";
		}
	}
	if(!defined($this->{logdir})) {
		return $this;
	}

	my $dirpath = $this->{logdir} . '/'
		. sprintf('%04d%02d', @localtime[5,4]);
	my @dirstat = stat($dirpath);

	my $path = $this->{logdir} . '/'
		. sprintf('%04d%02d/%02d-%02d.log', @localtime[5,4,3,2]);

	if(!exists($this->{cacheLogPath}) || !defined($dirstat[1]) || $path ne $this->{cacheLogPath}) {
		# month is changed.
		delete $this->{cacheLogFh};
		my $umask = umask(0);
		local($@);
		CORE::eval {
			use File::Path;
			my $dir = $path;
			$dir =~ s,/[^/]*$,,;
			mkpath($dir);
		};
		if ($@){
            print "Status: 500 Internal Server Error\r\n";
			print "Content-Type: text/plain\r\n\r\n";
			print "Failed to create a directory [$path]\n";
			warn "Failed to create a directory [$path] (logdirで指定されたログ用のディレクトリを作成できません)";
			$this->sendError(
				title => "TL LogError",
				error => "Failed to create a directory [$path]($!)",
				nologging => 1,
			);
			exit;
		}
		$this->{cacheLogPath} = $path;
		umask($umask);
	}

	my @stat = stat($path);
	if(!defined($this->{cacheLogFh}) || !defined($stat[1]) || ($this->{cacheLogInode} != $stat[1])) {

		# hour is changed.
		my $fh = $this->_gensym;
		if(!open($fh, ">>$path")) {
            print "Status: 500 Internal Server Error\r\n";
			print "Content-Type: text/plain\r\n\r\n";
			print "Failed to open [$path]\n";
			warn "Failed to open [$path] (logdirで指定されたログ用のディレクトリにアクセスできません)";
			$this->sendError(
				title => "TL LogError",
				error => "Failed to open a log [$path]($!)",
				nologging => 1,
			);
			exit;
		}
		binmode($fh);
		my @newstat = stat($path);
		$this->{cacheLogFh} = $fh;
		$this->{cacheLogInode} = $newstat[1];
		local($@);
		CORE::eval
		{
			my $rel_to_logfile = sprintf('%04d%02d/%02d-%02d.log', @localtime[5,4,3,2]);
			local($SIG{__DIE__}) = 'DEFAULT';
			my $cur_linkfile = File::Spec->catfile($this->{logdir}, "current");
			unlink($cur_linkfile);
			symlink($rel_to_logfile, $cur_linkfile);
		};
	}

	if( utf8::is_utf8($log) )
	{
		utf8::encode($log);
	}
	my $fh = $this->{cacheLogFh};
	flock($fh, 2);
	seek($fh, 0, 2);
	syswrite($fh, $log);
	flock($fh, 8);

	$this;
}

sub getLogHeader {
	my $this = shift;
	
	my $time = time;
	my @localtime = localtime($time);
	$localtime[4]++;
	$localtime[5] += 1900;

	sprintf('%02d:%02d:%02d(%08x) %04x %04x',
		@localtime[2,1,0], $time, $$, ($LOG_SERIAL % 0x10000));
}

sub setHook {
	my $this = shift;
	my $type = shift;
	my $priority = shift;
	my $code = shift;

	if(!defined($type)) {
		die __PACKAGE__."#setHook: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	if(ref($type)) {
		die __PACKAGE__."#setHook: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}
	if(!exists($this->{hook}{$type})) {
		die __PACKAGE__."#setHook: [$type] is an invalid hook type. (hook type の指定が不正です)\n";
	}
	if(!defined($priority)) {
		die __PACKAGE__."#setHook: arg[2] is not defined. (第2引数が指定されていません)\n";
	}
	if(ref($priority)) {
		die __PACKAGE__."#setHook: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}
	if($priority !~ m/^-?\d+$/) {
		die __PACKAGE__."#setHook: arg[2] must be an integer. [$priority] (priorityは整数のみ指定できます)\n";
	}
	if(ref($code) ne 'CODE') {
		die __PACKAGE__."#setHook: arg[3] is not a CODE Ref. (第3引数がコードリファレンスではありません)\n";
	}

	$this->{hook}{$type}{$priority} = $code;

	@{$this->{hooklist}{$type}} = map {
			$this->{hook}{$type}{$_};
		} sort {
			$a <=> $b;
		} keys %{$this->{hook}{$type}};

	$this;
}

sub removeHook {
	my $this = shift;
	my $type = shift;
	my $priority = shift;

	if(!defined($type)) {
		die __PACKAGE__."#removeHook: arg[1] is not defined. (第1引数が指定されていません)\n";
	}
	if(ref($type)) {
		die __PACKAGE__."#removeHook: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}
	if(!exists($this->{hook}{$type})) {
		die __PACKAGE__."#removeHook: [$type] is an invalid hook type. (hook type の指定が不正です)\n";
	}
	if(!defined($priority)) {
		die __PACKAGE__."#setHook: arg[2] is not defined. (第2引数が指定されていません)\n";
	}
	if(ref($priority)) {
		die __PACKAGE__."#setHook: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}

	delete $this->{hook}{$type}{$priority};

	@{$this->{hooklist}{$type}} = map {
			$this->{hook}{$type}{$_};
		} sort {
			$a <=> $b;
		} keys %{$this->{hook}{$type}};

	$this;
}

sub setContentFilter {
	my $this = shift;
	my $classname = shift;
	my $priority = 1000;
	my %option = @_;

	if(!defined($classname)) {
		die __PACKAGE__."#setContentFilter: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($classname) eq 'ARRAY') {
		($classname, $priority) = @$classname;
		if(!defined($classname)) {
			die __PACKAGE__."#setContentFilter: arg[1][0] is not defined. (第1引数の配列の1番目の要素にクラス名が指定されていません)\n";
		} elsif(ref($classname)) {
			die __PACKAGE__."#setContentFilter: arg[1][0] is a reference. (第1引数の配列の1番目の要素がリファレンスです)\n";
		}

		if (!defined($priority)) {
			die __PACKAGE__."#setContentFilter: arg[1][1] is not defined. (第1引数の配列の2番目の要素にプライオリティが指定されていません)\n";
		} elsif(ref($priority)) {
			die __PACKAGE__."#setContentFilter: arg[1][1] is a reference. (第1引数の配列の2番目の要素がリファレンスです)\n";
		} elsif($priority !~ m/^\d+$/) {
			die __PACKAGE__."#setContentFilter: arg[1][1] must be an integer. [$priority] (priorityは整数のみ指定できます)\n";
		}
	} elsif(ref($classname)) {
		die __PACKAGE__."#setContentFilter: arg[1] is not a scalar nor an ARRAY ref. (第1引数がスカラでも配列のリファレンスでもありません)\n";
	}

	do {
		local $SIG{__DIE__} = 'DEFAULT';
		CORE::eval "require $classname";
	};
	if($@) {
		die $@;
	}

	do {
		no strict;
		*{"${classname}\::TL"} = *Tripletail::TL;
	};

	$this->{filter}{$priority} = $classname->_new(%option);
	$this->_updateFilterList('filter');

	$this;
}

sub removeContentFilter {
	my $this = shift;
	my $priority = @_ ? shift : 1000;

	delete $this->{filter}{$priority};
	$this->_updateFilterList('filter');

	$this;
}

sub getContentFilter {
	my $this = shift;
	my $priority = @_ ? shift : 1000;

	$this->{filter}{$priority};
}

sub setInputFilter {
	my $this = shift;
	my $classname = shift;
	my $priority = 1000;
	my %option = @_;

	if (!defined($classname)) {
		die __PACKAGE__."#setInputFilter: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($classname) eq 'ARRAY') {
		($classname, $priority) = @$classname;
		if(!defined($classname)) {
			die __PACKAGE__."#setInputFilter: arg[1][0] is not defined. (第1引数の配列の1番目の要素にクラス名が指定されていません)\n";
		} elsif(ref($classname)) {
			die __PACKAGE__."#setInputFilter: arg[1][0] is a reference. (第1引数の配列の1番目の要素がリファレンスです)\n";
		}

		if(!defined($priority)) {
			die __PACKAGE__."#setInputFilter: arg[1][1] is not defined. (第1引数の配列の2番目の要素にプライオリティが指定されていません)\n";
		} elsif(ref($priority)) {
			die __PACKAGE__."#setInputFilter: arg[1][1] is a reference. (第1引数の配列の2番目の要素がリファレンスです)\n";
		} elsif($priority !~ m/^\d+$/) {
			die __PACKAGE__."#setInputFilter: arg[1][1] must be an integer. [$priority] (priorityは整数のみ指定できます)\n";
		}
	} elsif(ref($classname)) {
		die __PACKAGE__."#setInputFilter: arg[1] is not a scalar nor an ARRAY ref. (第1引数がスカラでも配列のリファレンスでもありません)\n";
	}

	do {
		local $SIG{__DIE__} = 'DEFAULT';
		CORE::eval "require $classname";
	};
	if($@) {
		die $@;
	}

	do {
		no strict;
		*{"${classname}\::TL"} = *Tripletail::TL;
	};

	$this->{inputfilter}{$priority} = $classname->_new(%option);
	$this->_updateFilterList('inputfilter');

	$this;
}

sub removeInputFilter {
	my $this = shift;
	my $priority = @_ ? shift : 1000;

	delete $this->{inputfilter}{$priority};
	$this->_updateFilterList('inputfilter');

	$this;
}

sub getInputFilter {
	my $this = shift;
	my $priority = @_ ? shift : 1000;

	$this->{inputfilter}{$priority};
}

sub _sendErrorIfNeeded {
    my $this = shift;
    my $err = shift;
    
    _isa($err, 'Tripletail::Error') or
      $err = $TL->newError('error' => $err);

    my $emtype = $this->INI->get(TL => 'errormailtype', 'error memory-leak');
    my $types = {map { $_ => 1 } split /\s+/, $emtype};

    if ($types->{$err->type}) {
        my $title  = 'Tripletail: ' . $err->title;
        my $maxlen = $this->INI->get(TL => errormail_subject_len => 100);

        $title =~ s/\r|\n/ /g;
        $title =~ s/[\x00-\x1F]//g;

        if (length($title) > $maxlen) {
            $title = substr($title, 0, $maxlen) . '...';
        }

        $this->sendError(
            title => $title,
            error => ($err->type eq 'error' ? "$err" : $err->message),
           );
    }
}

sub _hostname
{
	my $this = shift;
	my $host = $this->_readcmd("hostname -f 2>&1");
	$host ||= $this->_readcmd("hostname 2>&1");
	$host && $host=~/^\s*([\w.-]+)\s*$/ ? $1 : '';
}

sub sendError {
	my $this = shift;
	my $opts = { @_ };

	my ($rcpt, $group);
	if (defined(my $email = $this->INI->get(TL => 'errormail' => undef))) {
		if($email =~ m/^(.+?)%(.+)$/) {
			$rcpt = $1;
			$group = $2;
		} else {
			$rcpt = $email;
			$group = 'Sendmail';
		}
	} else {
		return;
	}

	local($@);

	if(!defined($opts->{title})) {
		$opts->{title} = "Untitled";
	}
	if(!defined($opts->{error})) {
		$opts->{title} = "Unknown Error";
	}

	my @lines;
	push @lines, "TITLE: $opts->{title}";
	push @lines, "ERROR: $opts->{error}";
	push @lines, '';
	push @lines, '----';

	my $host = $this->_hostname();
	if($host) {
		chomp $host;
		unshift @lines, "HOST: $host";
	}

	my $locinfo = '@' . ($host || '-');
	if(defined $0) {
		$locinfo = $0 . $locinfo;

		unshift @lines, "SCRIPT: $0";
	}

	if($this->{CGIORIG}) {
		foreach my $key ($this->{CGIORIG}->getKeys) {
			foreach my $data ($this->{CGIORIG}->getValues($key)) {
				push @lines, "[CGI:$key] $data";
			}
		}
	}

	foreach my $key (keys %ENV) {
		push @lines, "[ENV:$key] $ENV{$key}";
	}

	CORE::eval {
		my $mail = $this->newMail->setHeader(
				From    => $rcpt,
				To      => $rcpt,
				Subject => "$opts->{title} $locinfo",
		)->setBody(join "\n", @lines)->toStr;

		$this->newSendmail($group)->_setLogging(0)->connect->send(
			from => $rcpt,
			rcpt => $rcpt,
			data => $mail,
		)->disconnect;
	};
	if(my $err = $@) {
		if(! $opts->{nologging}) {
			$this->log(__PACKAGE__, "Failed to send an error mail: $err");
		}
	}
}

sub print {
	my $this = shift;
	my $data = shift;

	local $| = 1;

	if(!defined($data)) {
		die __PACKAGE__."#print: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	if(@{$this->{filterlist}} == 0) {
		# フィルタが一つも無い時はprintできない。
		die __PACKAGE__."#print: we have no content-filters. Set at least one filter. (コンテンツフィルタが指定されていません)\n";
	}

	foreach my $filter (@{$this->{filterlist}}) {
		$data = $filter->print($data);
	}
	if($this->{outputbuffering}) {
		$this->{outputbuff} .= $data;
	} else {
		print $data;
	}

	$this->{printflag} ||= 1;

	$this;
}

sub location {
	my $this = shift;
	my $url = shift;
	
	if(exists($this->{printflag})) {
		die __PACKAGE__."#location: \$TL->location() must not be called after calling \$TL->print(). (printを実行後にlocationが呼び出されました)\n";
	}
	
	$this->getContentFilter->_location($url);
	
	$this;
}

sub parsePeriod {
	# 時刻指定 (sec, min等) をパースし、秒数に変換する。
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die __PACKAGE__."#parsePeriod: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = lc($str);

	my $result = 0;

	my $lastnum = undef;
	local *commit = sub {
			my $unit = shift;

		if(!defined($lastnum)) {
			die __PACKAGE__."#parsePeriod: invalid time string [$str]:".
			" It has an isolated unit that does not follow any digits. (時刻指定が正しくありません。単位の前に数字がありません)\n";
		}

		$result += $lastnum * $unit;
		$lastnum = undef;
	};

	local($_) = $str;
	while(1) {
		length or last;

		s/^\s+//;

		if(s/^sec(?:onds?)?//) {
			commit(1);
		} elsif(s/^min(?:utes?)?//) {
			commit(60);
		} elsif(s/^hours?//) {
			commit(60 * 60);
		} elsif(s/^days?//) {
			commit(60 * 60 * 24);
		} elsif(s/^mon(?:ths?)?//) {
			commit(60 * 60 * 24 * 30.436875);
		} elsif(s/^years?//) {
			commit(60 * 60 * 24 * 365.2425);
		} elsif(s/^(\d+)//) {
			if(defined($lastnum)) {
				die __PACKAGE__."#parsePeriod: invalid time string [$str]:".
				" It has digits followed by another digits instead of unit. (時刻指定が正しくありません。単位の指定が足りません)\n";
			}

			$lastnum = $1;
		} else {
			die __PACKAGE__."#parsePeriod: invalid format: [$_] (形式が不正です)\n";
		}
	}

	if(defined($lastnum)) {
		commit(1);
	}

	int($result);
}

sub parseQuantity {
	# 量指定 (k, m等) をパースし、そのままの数に変換する。
	my $this = shift;
	my $str = shift;

	if(!defined($str)) {
		die __PACKAGE__."#parseQuantity: arg[1] is not defined. (第1引数が指定されていません)\n";
	}

	$str = lc($str);

	my $result = 0;

	my $lastnum = undef;
	local *commit = sub {
		my $unit = shift;

		if(!defined($lastnum)) {
			die __PACKAGE__."#parsePeriod: invalid quantity string [$str]:".
			" It has an isolated unit that does not follow any digits. (量指定が正しくありません。単位の前に数字がありません)\n";
		}

		$result += $lastnum * $unit;
		$lastnum = undef;
	};

	local($_) = $str;
	while(1) {
		length or last;

		s/^\s+//;

		if(s/^ki//) {
			commit(1024);
		} elsif(s/^mi//) {
			commit(1024 * 1024);
		} elsif(s/^gi//) {
			commit(1024 * 1024 * 1024);
		} elsif(s/^ti//) {
			commit(1024 * 1024 * 1024 * 1024);
		} elsif(s/^pi//) {
			commit(1024 * 1024 * 1024 * 1024 * 1024);
		} elsif(s/^ei//) {
			commit(1024 * 1024 * 1024 * 1024 * 1024 * 1024);
		} elsif(s/^k//) {
			commit(1000);
		} elsif(s/^m//) {
			commit(1000 * 1000);
		} elsif(s/^g//) {
			commit(1000 * 1000 * 1000);
		} elsif(s/^t//) {
			commit(1000 * 1000 * 1000 * 1000);
		} elsif(s/^p//) {
			commit(1000 * 1000 * 1000 * 1000 * 1000);
		} elsif(s/^e//) {
			commit(1000 * 1000 * 1000 * 1000 * 1000 * 1000);
		} elsif(s/^(\d+)//) {
			if(defined($lastnum)) {
				die __PACKAGE__."#parseQuantity: invalid quantity string [$str]:".
				" It has digits followed by another digits instead of unit. (量指定が正しくありません。単位の指定が足りません)\n";
			}

			$lastnum = $1;
		} else {
			die __PACKAGE__."#parsePeriod, invalid format: [$_] (形式が不正です)\n";
		}
	}

	if(defined($lastnum)) {
		commit(1);
	}

	$result;
}


sub getCookie {
	my $this = shift;

    if (not $IN_EXTENT_OF_STARTCGI) {
        die __PACKAGE__.'#getCookie: this method must not be called outside $TL->startCgi(). (このメソッドを $TL->startCgi() の外から呼ぶ事は出来ません。)';
    }

	require Tripletail::Cookie;

	Tripletail::Cookie->_getInstance(@_);
}

sub newDateTime {
	my $this = shift;

	require Tripletail::DateTime;

	Tripletail::DateTime->_new(@_);
}

sub getDB {
	my $this = shift;

	require Tripletail::DB;

	Tripletail::DB->_getInstance(@_);
}

sub newDB {
	my $this = shift;

	require Tripletail::DB;

	Tripletail::DB->_new(@_);
}

sub getDebug {
	my $this = shift;

	require Tripletail::Debug;
	
	Tripletail::Debug->_getInstance(@_);
}

sub getCsv {
	my $this = shift;

	require Tripletail::CSV;

	Tripletail::CSV->_getInstance(@_);
}

sub newForm {
	my $this = shift;

	require Tripletail::Form;

	*Tripletail::Form::TL = *Tripletail::TL;

	Tripletail::Form->_new(@_);
}

sub newHtmlFilter {
	my $this = shift;

	require Tripletail::HtmlFilter;

	Tripletail::HtmlFilter->_new(@_);
}

sub newHtmlMail {
	my $this = shift;

	require Tripletail::HtmlMail;

	Tripletail::HtmlMail->_new(@_);
}

sub newIni {
	my $this = shift;

	require Tripletail::Ini;

	*Tripletail::Ini::TL = *Tripletail::TL;

	Tripletail::Ini->_new(@_);
}

sub newMail {
	my $this = shift;

	require Tripletail::Mail;

	Tripletail::Mail->_new(@_);
}

sub newPager {
	my $this = shift;

	require Tripletail::Pager;

	Tripletail::Pager->_new(@_);
}

sub getRawCookie {
	my $this = shift;

    if (not $IN_EXTENT_OF_STARTCGI) {
        die __PACKAGE__.'#getRawCookie: this method must not be called outside $TL->startCgi(). (このメソッドを $TL->startCgi() の外から呼ぶ事は出来ません。)';
    }

	require Tripletail::RawCookie;

	Tripletail::RawCookie->_getInstance(@_);
}

sub newSendmail {
	my $this = shift;

	require Tripletail::Sendmail;

	Tripletail::Sendmail->_new(@_);
}

sub newSerializer {
    my $this = shift;
    my %opts = exists $_[0] ? %{+shift} : ();

    if (!exists $opts{-type} || $opts{-type} eq 'modern') {
        require Tripletail::Serializer;
        return Tripletail::Serializer->_new(@_);
    }
    elsif ($opts{-type} eq 'compat') {
        require Tripletail::Serializer::Compat;
        return Tripletail::Serializer::Compat->_new(@_);
    }
    elsif ($opts{-type} eq 'legacy') {
        require Tripletail::Serializer::Legacy;
        return Tripletail::Serializer::Legacy->_new(@_);
    }
    else {
        die "Unknown serializer type: $opts{-type}";
    }
}

sub newSMIME {
    my $this = shift;

    CORE::eval {
        require Crypt::SMIME;
    };
    if ($@) {
        die __PACKAGE__."#newSMIME: Crypt::SMIME is not available";
    }
    else {
        return Crypt::SMIME->new(@_);
    }
}

sub newTagCheck {
	my $this = shift;

	require Tripletail::TagCheck;

	Tripletail::TagCheck->_new(@_);
}

sub newTemplate {
    my $this = shift;

    require Tripletail::Template;

    return Tripletail::Template->_new(@_);
}

sub getSession {
	my $this = shift;

	require Tripletail::Session;

	Tripletail::Session->_getInstance(@_);
}

sub newValue {
	my $this = shift;

	require Tripletail::Value;

	Tripletail::Value->_new(@_);
}

sub newValidator {
	my $this = shift;
	
	require Tripletail::Validator;
	
	Tripletail::Validator->_new(@_);
}

sub newError {
	my $this = shift;

	# Tripletail::Error のロード失敗は特別に扱わなければならない。
	# die ハンドラがこれを利用する為である。
	if( !Tripletail::Error->can("_new") )
	{
		local($@);
		CORE::eval {
			require Tripletail::Error;
		};
		if ($@) {
			print STDERR $@;
			if( $@ =~ /BEGIN not safe after errors--compilation aborted/ )
			{
				print STDERR "--\nsee: perldoc perldiag\n> BEGIN not safe after errors--compilation aborted\n";
			}
			my ($type, $msg, ) = @_;
			print STDERR "--\n[$type]\n$msg";
			exit 1;
		}
	}

	Tripletail::Error->_new(@_);
}

sub getMemorySentinel {
	my $this = shift;

	require Tripletail::MemorySentinel;

	Tripletail::MemorySentinel->_getInstance(@_);
}

sub getFileSentinel {
	my $this = shift;

	require Tripletail::FileSentinel;

	Tripletail::FileSentinel->_getInstance(@_);
}

sub newMemCached {
	my $this = shift;

	require Tripletail::MemCached;

	Tripletail::MemCached->_new();
}

sub charconv {
	my $this = shift;

	require Tripletail::CharConv;

	Tripletail::CharConv->_getInstance()->_charconv(@_);
}

# -----------------------------------------------------------------------------
# ファイル関連.
# -----------------------------------------------------------------------------

sub _filecacheMax
{
	my $this = shift;
	@_ and $_FILE_CACHE_MAXSIZE = shift;
	$_FILE_CACHE_MAXSIZE;
}

sub _filecacheMemorySize
{
	$_FILE_CACHE_CURSIZE;
}

sub _fetchFileCache
{
	my $this = shift;
	my $fpath = shift;
	
	my $now = time;
	
	my ($inode, $size, $mtime);
	
	if( my $cache = $_FILE_CACHE{$fpath} )
	{
		if( $cache->{fetch_at}==$now )
		{
			return $cache;
		}
		
		my @st = stat($fpath);
		if( !@st )
		{
			if( $!{ENOENT} )
			{
				die __PACKAGE__."#_fetchFileCache: failed to stat file [$fpath]: $! (ファイルをstatできません; ファイルが存在しません)\n";
			}else
			{
				die __PACKAGE__."#_fetchFileCache: failed to stat file [$fpath]: $! (ファイルをstatできません)\n";
			}
		}
		($inode, $size, $mtime) = @st[1, 7, 9];
		if( $inode==$cache->{inode} && $size==$cache->{size} && $mtime==$cache->{mtime} )
		{
			$cache->{fetch_at} = $now;
			return $cache;
		}
		
		# unload.
		$_FILE_CACHE_CURSIZE -= $cache->{cache_size};
		delete $_FILE_CACHE{$fpath};
	}else
	{
		my @st = stat($fpath);
		if( !@st )
		{
			if( $!{ENOENT} )
			{
				die __PACKAGE__."#_fetchFileCache: failed to stat file [$fpath]: $! (ファイルをstatできません; ファイルが存在しません)\n";
			}else
			{
				die __PACKAGE__."#_fetchFileCache: failed to stat file [$fpath]: $! (ファイルをstatできません)\n";
			}
		}
		($inode, $size, $mtime) = @st[1, 7, 9];
	}
	
	my $cache = {
		inode => $inode,
		size  => $size,
		mtime => $mtime,
		path  => $fpath,
		data  => undef,
		text  => undef,
		
		fetch_at   => $now,
		cache_size => 312 + 24*5 + (25+length($fpath)) + 12*2,
	};
	if( $mtime < $now )
	{
		$_FILE_CACHE{$fpath} = $cache;
		$_FILE_CACHE_CURSIZE += $cache->{cache_size};
	}else
	{
		$cache->{cache_size} = undef;
	}
	$cache;
}

sub readFile {
	my $this = shift;
	my $fpath = shift;

	if(!defined($fpath)) {
		die __PACKAGE__."#readFile: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($fpath)) {
		die __PACKAGE__."#readFile: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}

	my $cache = $this->_fetchFileCache($fpath);
	if( !defined($cache->{data}) )
	{
		open my $fh, '<', $fpath
			or die __PACKAGE__."#readFile: failed to read file [$fpath]: $! (ファイルをstatできません)\n";

		local $/ = undef;
		$cache->{data} = <$fh>;
		if( $cache->{cache_size} )
		{
			$cache->{cache_size} += 25 + length($cache->{data});
			$_FILE_CACHE_CURSIZE  += 25 + length($cache->{data});
		}
	}
	$cache->{data};
}

sub readTextFile {
	my $this = shift;
	my $fpath = shift;
	my $coding = shift;

	my $cache = $this->_fetchFileCache($fpath);
	if( !defined($cache->{text}) )
	{
		$cache->{text} = $this->charconv(
			$this->readFile($fpath),
			$coding,
			'UTF-8',
		);
		if( $cache->{cache_size} )
		{
			$cache->{cache_size} += 25 + length($cache->{text});
			$_FILE_CACHE_CURSIZE += 25 + length($cache->{text});
		}
		
		# rawデータは使わないと思うので削除.
		if( defined($cache->{data}) )
		{
			if( $cache->{cache_size} )
			{
				$cache->{cache_size} -= 25 + length($cache->{data});
				$_FILE_CACHE_CURSIZE -= 25 + length($cache->{data});
			}
			delete $cache->{data};
		}
	}
	$cache->{text};
}

sub writeFile {
	my $this = shift;
	my $fpath = shift;
	my $fdata = shift;
	my $fmode = shift;

	if(!defined($fpath)) {
		die __PACKAGE__."#writeFile: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($fpath)) {
		die __PACKAGE__."#writeFile: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}
	
	$fmode = 0 if(!defined($fmode));

	my $fmode_str = '>';
	$fmode_str = '>>' if($fmode == 1);

	open my $fh, $fmode_str, $fpath
	  or die __PACKAGE__."#writeFile: failed to read file [$fpath]: $! (ファイルを読めません)\n";
	print $fh $fdata;
	close $fh;

}

sub writeTextFile {
	my $this = shift;
	my $fpath = shift;
	my $fdata = shift;
	my $fmode = shift;
	my $coding = shift;

	if(!defined($coding)) {
		$coding = 'UTF-8';
	}
	if(ref($coding)) {
		die __PACKAGE__."#writeTextFile: arg[4] is a reference. (第4引数がリファレンスです)\n";
	}

	$this->writeFile($fpath,$this->charconv($fdata,'UTF-8',$coding,),$fmode);
}

# -----------------------------------------------------------------------------
# --
# -----------------------------------------------------------------------------
sub watch {
	my $this = shift;

	require Tripletail::Debug::Watch;

	Tripletail::Debug::Watch::watch(@_);
}

sub dump {
    # dump($group, $obj)
    # dump($group, $obj, $level)
    # dump($obj)
    # dump($obj, $level)
	my $this = shift;
    my $group;
    my $val;
    my $level;

    my $auto_group = sub {
        # "呼出し元ファイル名(行数):関数名"
        my ($filename, $line) = (caller 1)[1, 2];
        my $sub = (caller 2)[3];

        sprintf '%s(%d) >> %s', $filename, $line, $sub;
    };

    if (@_ == 0 || @_ > 3) {
        die __PACKAGE__."#dump: invalid call of \$TL->dump(). (引数の数が正しくありません)\n";
    }
    elsif (@_ == 1) {
        $group = $auto_group->();
        $val   = shift;
        $level = 0;
    }
    elsif (@_ == 2) {
        if (ref $_[0]) {
            # dump($obj, $level)
            $group = $auto_group->();
            $val   = shift;
            $level = shift;
        }
        else {
            # dump($group, $obj)
            $group = shift;
            $val   = shift;
            $level = 0;
        }
    }
    elsif (@_ == 3) {
        $group = shift;
        $val   = shift;
        $level = shift;
    }
    else {
        die "Internal error";
    }

    my $dump = Data::Dumper->new([$val])
      ->Indent(1)->Purity(0)->Useqq(1)->Terse(1)->Deepcopy(1)
        ->Quotekeys(0)->Sortkeys(1)->Deparse(1)->Maxdepth($level)->Dump;

    $this->log($group => $dump);
}

sub setCacheFilter {
	my $this = shift;
	my $form = shift;
	my $charset = shift;
	
	if(!defined($form)) {
		die __PACKAGE__."#setCacheFilter: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($form) eq 'HASH') {
		$form = $TL->newForm($form);
	} elsif(ref($form) ne 'Tripletail::Form') {
		die __PACKAGE__."#setCacheFilter: arg[1] is neither an instance of Tripletail::Form nor a HASH Ref. (第1引数がFormオブジェクトではありません)\n";
	}
	if(ref($charset)) {
		die __PACKAGE__."#setCacheFilter: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}
	
	$charset = 'Shift_JIS' if(!defined($charset));

	$this->{memcache_form} = $form;
	$this->{memcache_charset} = $charset;
}

sub printCacheUnlessModified {
	my $this = shift;
	my $key = shift;
	my $status = shift;

	if(!defined($key)) {
		die __PACKAGE__."#printCacheUnlessModified: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#printCacheUnlessModified: arg[1] is a reference. [$key] (第1引数がリファレンスです)\n";
	}
	
	if(!defined($status)) {
		$status = 304;
	} elsif(ref($status)) {
		die __PACKAGE__."#printCacheUnlessModified: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
	} elsif($status ne '200' && $status ne '304') {
		die __PACKAGE__."#printCacheUnlessModified: arg[2] is neither 200 nor 304. [$key] (第2引数は200か304のみ指定できます)\n";
	}

	my $cachedata = $TL->newMemCached->get($key);
	return 1 if(!defined($cachedata));
	if($cachedata =~ s/^(\d+),//) {
		my $cachetime = $1;
		if($status eq '304') {
			my $http_if_modified_since = $ENV{HTTP_IF_MODIFIED_SINCE};
			if(defined($http_if_modified_since)) {
				#;より後ろのデータは日付ではないので落とす
				$http_if_modified_since =~ s/;.+//;
				if($TL->newDateTime($http_if_modified_since)->getEpoch >= $cachetime) {
					$TL->setContentFilter('Tripletail::Filter::HeaderOnly');
					$TL->getContentFilter->setHeader('Status' => '304');
					$TL->getContentFilter->setHeader('Last-Modified' => $TL->newDateTime->setEpoch($cachetime)->toStr('rfc822'));
					return undef;
				}
			}
		}
		if(exists($this->{memcache_form}) && defined($this->{memcache_form})) {
			$this->{memcache_charset} = 'Shift_JIS' if(!exists($this->{memcache_charset}) || !defined($this->{memcache_charset}));
			foreach my $key2 ($this->{memcache_form}->getKeys){
				my $val = $TL->charconv($this->{memcache_form}->get($key2), 'UTF-8' => $this->{memcache_charset});
				$cachedata =~ s/$key2/$val/g;
			}
		}
		$TL->setContentFilter('Tripletail::Filter::MemCached',key => $key, mode => 'pass-through', cachedata => $cachedata);
		return undef;
	}
	1;
}

sub setCache {
	my $this = shift;
	my $key = shift;
	my $priority = shift;

	if(!defined($key)) {
		die __PACKAGE__."#setCache: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#setCache: arg[1] is a reference. [$key] (第1引数がリファレンスです)\n";
	}
	if(ref($priority)) {
		die __PACKAGE__."#setCache: arg[2] is a reference. (第2引数がリファレンスです)\n";
	}

	$priority = 1500 if(!defined($priority));
	$this->{memcache_charset} = 'Shift_JIS' if(!exists($this->{memcache_charset}) || !defined($this->{memcache_charset}));

	if(exists($this->{memcache_form}) && defined($this->{memcache_form})) {
		$TL->setContentFilter(['Tripletail::Filter::MemCached',$priority],key => $key, mode => 'write', form => $this->{memcache_form},  formcharset => $this->{memcache_charset});
	} else {
		$TL->setContentFilter(['Tripletail::Filter::MemCached',$priority],key => $key, mode => 'write');
	}
}

sub deleteCache {
	my $this = shift;
	my $key = shift;

	if(!defined($key)) {
		die __PACKAGE__."#deleteCache: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#deleteCache: arg[1] is a reference. [$key] (第1引数がリファレンスです)\n";
	}

	$TL->newMemCached->delete($key);
}

sub _gensym {
	package Tripletail::Symbol;
	no strict;
	$genpkg = "Tripletail::Symbol::";
	$genseq = 0;

	my $name = "GEN" . $genseq++;
	my $ref = \*{$genpkg . $name};
	delete $$genpkg{$name};

	$ref;
}

sub _getRunMode
{
	my $this = shift;

	if( _isa(tied(*STDIN), "FCGI::Stream") )
	{
		# already in fcgi-request.
		return 'FCGI';
	}
	if( defined(fileno(STDIN)) && !defined(getpeername(STDIN)) and $!{ENOTCONN} ) {
		# http://www.fastcgi.com/devkit/doc/fcgi-spec.html#S2.2
		# but win32 says ENOTSOCK.
		return 'FCGI';
	}
	if( $ENV{GATEWAY_INTERFACE} )
	{
		return 'CGI';
	}
	if( $^O eq 'MSWin32' )
	{
		if( !defined($IS_FCGI_WIN32) )
		{
			local($@);
			local $SIG{__DIE__} = 'DEFAULT';
			CORE::eval 'use FCGI';
			if( $@ )
			{
				$IS_FCGI_WIN32 = 0;
				$FCGI_LOADMSG_WIN32 = $@;
			}else
			{
				my $req = FCGI::Request();
				$IS_FCGI_WIN32 = $req->IsFastCGI();
				$FCGI_LOADMSG_WIN32 = $IS_FCGI_WIN32 ? '' : 'No FCGI Enviconment';
			}
		}
		if( $IS_FCGI_WIN32 )
		{
			return 'FCGI';
		}
	}
	'script';
}

sub _decodeFromURL {
	my $this = shift;
	my $url = shift;

	if(@{$this->{inputfilterlist}} == 0) {
		# フィルタが一つも無い時はデコードできない。
		die __PACKAGE__."#_decodeFromURL: we have no input-filters. Set at least one filter. (入力フィルタが1つも指定されていません)\n";
	}

	# フラグメントを除去
	my $fragment;
	if($url =~ s/#(.+)$//) {
		$fragment = $1;
	}

	# 最初に空のTripletail::Formを作り、それを順々にフィルタに通して行く。
	my $form = $this->newForm;
	foreach my $filter (@{$this->{inputfilterlist}}) {
		$filter->decodeURL($form, $url, $fragment);
	}

	($form, $fragment);
}

sub _saveContentFilter {
	my $this = shift;
	
	%{$this->{saved_filter}} = %{$this->{filter}};
	$this->_updateFilterList('filter');
}

sub _restoreContentFilter {
	my $this = shift;

	%{$this->{filter}} = %{$this->{saved_filter}};
	$this->_updateFilterList('filter');

	%{$this->{saved_filter}} = ();
}

sub _updateFilterList {
	my $this = shift;
	my $key = shift;
	my $listkey = $key . 'list';

	@{$this->{$listkey}} =
		map { $this->{$key}{$_} }
			(sort {$a <=> $b} keys %{$this->{$key}});
}

sub __decodeCgi {
	my $this = shift;

	if(@{$this->{inputfilterlist}} == 0) {
		# フィルタが一つも無い時はデコードできない。
		die __PACKAGE__."#__decodeCgi: we have no input-filters. Set at least one filter. (入力フィルタが1つも指定されていません)\n";
	}

	# 最初に空のTripletail::Formを作り、それを順々にフィルタに通して行く。
	my $form = $this->newForm;
	foreach my $filter (@{$this->{inputfilterlist}}) {
		$filter->decodeCgi($form);
	}

	$form;
}

sub __executeHook {
	my $this = shift;
	my $type = shift;

	foreach (@{$this->{hooklist}{$type}}) {
		$_->();
	}

	$this;
}

sub __dispError {
	my $this = shift;
	my $err  = shift;

	_isa($err, 'Tripletail::Error') or
	  $err = $TL->newError('error' => $err);

	my $errortemplate = $TL->INI->get(TL => 'errortemplate', '');
	my $http_headers;
	my $html;
    if ($this->{printflag} and not $this->{outputbuffering}) {
        $html = "<p>$err</p>";
        $html =~ s!\n!<br />!g;
        my $filter = $this->getContentFilter();
        $http_headers = $filter->{header_flushed} ? '' : $filter->_flush_header();
    }
	elsif (length $errortemplate) {
		my $t = $TL->newTemplate($errortemplate);
		my $errortemplatecharset = $this->INI->get(TL => 'errortemplatecharset', 'UTF-8');
		$html = $TL->charconv($t->toStr, 'UTF-8', $errortemplatecharset);

		my $status = ref($err) && $err->{http_status_line};
		$status ||= '500 Internal Server Error';
		$http_headers  = "Status: $status\r\n";
		$http_headers .= "Content-Type: text/html; charset=$errortemplatecharset\r\n";
		$http_headers .= "\r\n";
	}
    else {
		my $popup = $TL->getDebug->_implant_disperror_popup;
		$html = $err->toHtml;
		$html =~ s|</html>$|$popup</html>|;

		my $status = ref($err) && $err->{http_status_line};
		$status ||= '500 Internal Server Error';
		$http_headers  = "Status: $status\r\n";
		$http_headers .= "Content-Type: text/html; charset=UTF-8\r\n";
		$http_headers .= "\r\n";
	}

	print $http_headers.$html;

	$this->_sendErrorIfNeeded($err);

	my $errorlog = $this->INI->get(TL => 'errorlog', 1);
	if($errorlog > 0) {
		$this->log(__PACKAGE__, "$err");
	}
	if($errorlog > 1) {
		$TL->getDebug->__log_request;
	}
}

sub __executeCgi {
	my $this = shift;
	my $mainfunc = shift;

	$LOG_SERIAL++;
	
	$this->__executeHook('initRequest');
	
	# ここで$CGIを作り、constにする。
	$this->{CGIORIG} = CORE::eval { $this->__decodeCgi->const };
	if ($@) {
		die $@ if not (
			ref($@)
				and
			_isa($@, "Tripletail::Error")
				and
			(
				($@->message =~ /we got IO error while reading from stdin/)
					or
				($@->message =~ /we got EOF while reading from stdin/)
			)
		);
		print "Status: 500 Internal Server Error\r\n";
		print "Content-Type: text/plain\r\n\r\nI/O Error\r\n$@";
	}
	else {
		$this->{CGI} = $this->{CGIORIG}->clone;
		if( !$TL->INI->get(TL => 'allow_mutable_input_cgi_object' => 0) )
		{
			$this->{CGI}->const();
		}
		$this->{CGI}->_trace();
		our $CGI = $this->{CGI};
		$this->{outputbuff} = '';

		# $CGI の export
		my $callpkg = caller(2);
		{
			no strict "refs";
			*{"$callpkg\::CGI"} = *{"Tripletail::CGI"};
		}

		$this->__executeHook('preRequest');
		$this->_saveContentFilter;

		CORE::eval {
			$mainfunc->();
		};
		if($@) {
			$this->__dispError($@);
		} else {
			$this->__flushContentFilter;
		}
		$this->__resetContentFilter();

		$this->_restoreContentFilter();
		$this->__executeHook('postRequest');
	}

	# $CGIを消す。
	$this->{CGI} = undef;
	$this->{CGIORIG} = undef;
	$this->{outputbuff} = '';
	$this;
}

sub __flushContentFilter {
	my $this = shift;

	delete $this->{printflag};

	my $add_clen;
	if( $this->{outputbuffering} && !$TL->{mod_perl} )
	{
		my $filter = $this->getContentFilter();
		if( !exists($filter->{replacement}{'Content-Length'}) && !exists($filter->{addition}{'Content-Length'}) )
		{
			$add_clen = 1;
		}
	}


	my $str = '';
	foreach my $filter (@{$this->{filterlist}}) {
		$str = $filter->print($str);
		$str .= $filter->flush;
	}
	$str = $this->{outputbuff} . $str;

	if( $add_clen )
	{
		my $body = $str;
		$body =~ s/^.*?(?:\r?\n\r?\n|\r\r)//s;
		my $clen = length($body);
		$str = "Content-Length: $clen\r\n" . $str;
	}

	print $str;
}

sub __resetContentFilter {
	my $this = shift;

	delete $this->{printflag};

	foreach my $filter (@{$this->{filterlist}})
	{
		my $sub = $filter->can('reset');
		if( $sub )
		{
			$filter->$sub();
		}
	}
}

sub _cwd
{
	$CWD ||= Cwd::cwd;
}
sub _clearCwd
{
	$CWD = undef;
}

sub _readcmd
{
	my $this = shift;
	my $cmd = shift;
	my $secure_env = $this->_secure_env();
	local(%ENV) = %$secure_env;
	`$cmd`;
}
sub _secure_env
{
	my $this = shift;
	my $uid = $<;
	my ($username, $home);
	if( $^O ne 'MSWin32' )
	{
		$username = getpwuid($uid);
		$home     = (getpwuid($uid))[7];
	}else
	{
		$username = 'anonymous';
		$home     = 'C:/';
	}
	+{
		LANG => 'C',
		PATH => '/bin:/usr/bin',
		USER => $username,
		HOME => $home,
		SHELL => '/bin/sh',
	};
}

sub _isa
{
	my $val  = shift;
	my $type = shift;
	defined($type) or die 'undefined arg:type';
	defined($val)  or return; # false.
	if( defined(ref($val)) )
	{
		return ref($val) eq $type || (blessed($val) && $val->isa($type));
	}else
	{
		local($@);
		local($SIG{__DIE__}) = 'DEFAULT';
		my $ret = eval { $val->isa($type); };
		$@ and print STDERR __PACKAGE__."._isa: $@";
		$ret;
	}
}

__END__

=encoding utf-8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT
	AU
	CGI
	FCGI
	fcgi
	FastCGI
	Ki
	Mi
	Gi
	Ti
	Pi
	Ei
	TL
	UTF-8
	Shift_JIS
	EUC-JP
	ISO-2022-JP
	Unicode
	YMIRLINK
	const
	diewithprint
	init
	ini
	inigroup
	errorlog
	errormail
	errormailtype
	errortemplate
	errortemplatecharset
	escapeJs
	escapeJsString
	PadWalker
	MemCached
	memcached
	mon
	fcgilog
	filelog
	imode
	sjis-imode
	ja
	printCacheUnlessModified
	setContentFilter
	startCgi


=head1 NAME

Tripletail - Tripletail, Framework for Japanese Web Application

=head1 NAME (ja)

Tripletail - Tripletail, 日本語向けウェブアプリケーションフレームワーク

=head1 SYNOPSIS

  use Tripletail qw(tl.ini);
  
  $TL->startCgi(
      -main => \&main,
  );
  
  sub main {
      my $t = $TL->newTemplate('index.html');

      $t->flush;
  }
  
=head1 DESCRIPTION

=head2 C<use>

Tripletail では、ライブラリの各種設定は L<Ini|Tripletail::Ini> ファイルに置かれる。

実行が開始されるスクリプトの先頭で、次のように引数として L<Ini|Tripletail::Ini>
ファイルの位置を渡す。するとグローバル変数 C<$TL> がエクスポートされる。
L<Ini|Tripletail::Ini> ファイル指定は必須である。

  use Tripletail qw(/home/www/ini/tl.ini);

他のファイルから C<$TL> 変数を使う場合は、そのパッケージ内で
C<use Tripletail;> のように引数無しで C<use> する。二度目以降の C<use> で
L<Ini|Tripletail::Ini> ファイルの位置を指定しようとした場合はエラーとなる。

設定ファイルの設定値のうち、一部の値を特定の CGI で変更したい場合は、
次のように2つめ以降引数に特化指定をすることが出来る。

  use Tripletail qw(/home/www/ini/tl.ini golduser);

特化指定を行った場合、ライブラリ内で Ini ファイルを参照する際に、
まず「グループ名 + ":" + 特化指定値」のグループで検索を行う。
結果がなかった場合は、通常のグループ名の指定値が使用される。

また、サーバの IP やリモートの IP により使用するグループを変更することも出来る。それぞれ
「グループ名 + "@sever" + 使用するサーバのマスク値」
「グループ名 + "@remote" + 使用するリモートのマスク値」
といった書式となる。

但し、スクリプトで起動した場合、リモートの IP 指定している項目は全て無視される。
サーバの IP 指定している項目の場合、 C<hostname -i> で取得した値でマッチされる。

使用するサーバのマスク値と、リモートのマスク値に関しては、Ini中の[HOST]グループに設定する。例えば次のようになる。

  [HOST]
  Debughost = 192.168.10.0/24
  Testuser = 192.168.11.5 192.168.11.50
  [TL@server:Debughost]
  logdir = /home/tl/logs
  errormail = tl@example.org
  [TL@server:Debughost]
  logdir = /home/tl/logs/register

マスクは空白で区切って複数個指定する事が可能。

但し、[HOST]には特化指定は利用できない。

特化指定を二種、もしくは、三種を組み合わせて利用することも出来るが、その場合の順序は「グループ名 + ":" + 特化指定値 + "@sever" + 使用するサーバのマスク値 + "@remote" + 使用するリモートのマスク値」で固定であり、その他の並びで指定することは出来ない。

特化指定は複数行うことができ、その場合は最初の方に書いたものほど優先的に使用される。 

=head2 特化指定

特化指定の具体的例を示す

  [HOST]
  Debughost = 192.168.10.0/24
  Testuser = 192.168.11.5 192.168.11.50
  [TL:register@server:Debughost]
  logdir = /home/tl/logs/register/debug
  [TL@server:Debughost]
  logdir = /home/tl/logs
  errormail = tl@example.org
  [TL]
  logdir = /home/tl/logs
  [TL:register]
  logdir = /home/tl/logs/register
  [Debug@remote:Testuser]
  enable_debug=1

という F<tl.ini> が存在している場合に

  use Tripletail qw(/home/www/ini/tl.ini register);

で、起動した場合、次のような動作になる。

プログラムが動いているサーバが、192.168.10.0/24であり、アクセスした箇所の IP が192.168.11.5か192.168.11.50である場合

  [TL]
  logdir = /home/tl/logs/register/debug
  errormail = tl@example.org
  [Debug]
  enable_debug=1

プログラムが動いているサーバが、192.168.10.0/24であり、アクセスした箇所の IP が192.168.11.5か192.168.11.50では無い場合

  [TL]
  logdir = /home/tl/logs/register

また、

  use Tripletail qw(/home/www/ini/tl.ini);

で、起動した場合、次のような動作になる。

プログラムが動いているサーバが、192.168.10.0/24であり、アクセスした箇所の IP が192.168.11.5か192.168.11.50である場合

  [TL]
  logdir = /home/tl/logs/debug
  errormail = tl@example.org
  [Debug]
  enable_debug=1

プログラムが動いているサーバが、192.168.10.0/24であり、アクセスした箇所の IP が192.168.11.5か192.168.11.50では無い場合

  [TL]
  logdir = /home/tl/logs


=head2 携帯向け設定

以下のように、L<Tripletail::InputFilter::MobileHTML> 入力フィルタと
L<Tripletail::Filter::MobileHTML> 出力フィルタを利用することで、
携帯絵文字を含めて扱うことができる。

  use Tripletail qw(tl.ini);
  
  # startCgi前に入力フィルタを設定する
  $TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
  $TL->startCgi(
      -main => \&main,
  );
  
  sub main {
      # mainの最初で出力フィルタを設定する
      $TL->setContentFilter('Tripletail::Filter::MobileHTML');
      my $t = $TL->newTemplate('index.html');
      
      $t->flush;
  }

入力された絵文字は、 Unicode のプライベート領域にマップされる。
この文字は、 UTF-8 で4バイトの長さとなるため、DBに保存する場合などには
注意が必要となる。BLOB型など、バイナリ形式で保存すると安全である。

絵文字は出力時に各端末にあわせて変換される。
同じ携帯キャリアであれば元の絵文字に戻され、
他のキャリアであれば Unicode::Japanese の変換マップに従い変換されて出力される。

変換マップで該当する絵文字が無い場合や、PC 向けに出力した場合は「?」に変換される。

テンプレートファイルで絵文字を使う場合は、絵文字コードをバイナリで
埋め込む必要がある。
バイナリで埋め込まれた絵文字は Unicode::Japanese で自動判別される。
sjis-imode (DoCoMo)、sjis-jsky (Softbank)、sjis-au (AU) などが利用できるが、
複数の携帯キャリアの絵文字を混在させることはできない。


=head2 キャッシュの利用

Cache::Memcachedがインストールされ、 memcached サーバがある場合に、キャッシュが利用可能となる。

具体例は次の通り

INI ファイルにて、 memcached が動いているサーバを指定する。
[MemCached]
servers = localhost:11211

=over 4

=item 読み込み側例（ページ全体をキャッシュ）

  #まず、画面毎にキーを設定する。例のケースではtopという名称を付けている。
  #ページャーなどを利用する場合、キーはページ毎に設定する必要がある点を注意する（page-1等にする）
  #キーで検索を行い、キャッシュにヒットした場合、時間を比較して304でリダイレクトするか、
  #メモリから読み込んで表示する
  #printCacheUnlessModifiedでundefが返ってきた後は、printやflushなど出力する操作は不可なため注意する事
  return if(!defined($TL->printCacheUnlessModified('top')));
  #キャッシュすることを宣言する。なお、宣言はprintCacheUnlessModifiedより後で
  #printより前であれば、どの時点で行ってもかまわない
  $TL->setCache('top');

  #実際のスクリプトを記述し、出力を行う
  
  $TL->print('test code.');

=item 書き込み側例（ページ全体をキャッシュ）

  #書き込みを行った場合、そのデータを表示する可能性があるキャッシュを全て削除する
  #削除漏れがあると、キャッシュしている内容が表示され、更新されてないように見えるので注意する事。
  $TL->deleteCache('top');
  $TL->deleteCache('top2');

=item 読み込み側例（ユーザー名等一部に固有の情報を埋め込んでいる場合）

  #クッキーデータの取得、クッキーに固有の情報を入れておくと高速に動作出来る
  #（DB等から読み込みTripletail::Formクラスにセットしても可）
  my $cookiedata = $TL->getCookie->get('TLTEST');
  $cookiedata->set('<#NAME>' => $name) if(!$cookiedata->exists('name'));
  $cookiedata->set('<#POINT>' => $point) if(!$cookiedata->exists('point'));

  #まず、画面毎にキーを設定する。例のケースではtopという名称を付けている。
  #固有情報が変更された場合、ブラウザ側のキャッシュ情報をクリアしないと情報が変わらない為、
  #固有情報が変更される恐れがある場合は、304によるキャッシュは無効にする必要がある。
  #
  #固有の情報を置換するための情報をセットすると、キーがそのまま置換される。
  #その他の条件はページ全体をキャッシュする場合と同様。
  $TL->setCacheFilter($cookiedata);
  return if(!defined($TL->printCacheUnlessModified('top','200')));
  #キャッシュすることを宣言する。
  $TL->setCache('top');

  #実際のスクリプトを記述し、出力を行う
  #この際、固有の情報の部分に関しては、特殊タグ（文字列）に置換する。特殊タグはどのような形でもかまわないが、
  #出力文字列中の全ての同様の特殊タグが変換対象になるため、ユーザーや管理者が任意に変更出来る部分に注意する。
  #（エスケープする、その特殊タグが入力された場合エラーにするetc）
  
  $t->setAttr(
    NAME => 'raw',
    POINT => 'raw',
  );
  
  $t->expand(
    NAME => '<#NAME>',
    POINT => '<#POINT>',
  );

  
  $t->flush;

=item 書き込み側例（ユーザー名等一部に固有の情報を埋め込んでいる場合）

  #書き込みを行った場合、そのデータを表示する可能性があるキャッシュを全て削除する
  #削除漏れがあると、キャッシュしている内容が必要な為注意が必要。
  #必要があれば、固有の文字列を出力用にクッキーなどに書き出したりする。
  $TL->getCookie->set(TLTEST => $TL->newForm('<#NAME>' => $CGI->get('name'),'<#POINT>' => 1000));

  $TL->deleteCache('top');
  $TL->deleteCache('top2');


=back

=head2 実行モード

実行モードには次の三つがある。

=over 4

=item CGI モード

CGI としてプログラムを動作させるモード。このモードでは C<< $TL->print >>
メソッドや L</"出力フィルタ"> 、 L</"入力フィルタ"> が利用可能になる。

このモードでは L<< $TL->startCgi|/"startCgi" >> メソッドで L</"Main 関数"> を呼ぶ。

=item FastCGI モード

FastCGI としてプログラムを動作させるモード。httpd から fcgi スクリプトとして起動
しようとすると、自動的に選ばれる。このモードではプロセスのメモリ使用量を
監視し、起動後にある一定の大きさを越えてメモリ使用量が増大すると、メモリリーク
が発生しているとして自動的に終了する。また、 L<Ini|Tripletail::Ini> パラメータ付きで
C<use Tripletail> したスクリプトファイルや、その L<Ini|Tripletail::Ini> ファイルの最終更新時刻
も監視し、更新されていたら自動的に終了する。

このモードでは L<< $TL->startCgi|/"startCgi" >> メソッドで L</"Main 関数"> を呼ぶ。

FastCGI モードでは fork が正しく動作しない事に注意。代わりに
L<< $TL->fork|/"fork" >> メソッドを使用する。

=item 一般スクリプトモード

CGI でない一般のスクリプトとしてプログラムを動作させるモード。
CGI モード特有の機能は利用出来ない。

このモードでは L<< $TL->trapError|/"trapError" >> メソッドで L</"Main 関数"> を呼ぶ。

=back


=head2 出力フィルタ

L<< $TL->print|/"print" >> や L<< $template->flush|Tripletail::Template/"flush" >>
で出力される内容は、 L<Tripletail::Filter> によって加工される。出力の先頭に HTTP ヘッダを
付加するのも出力フィルタである。


=head2 入力フィルタ

C<< $ENV{QUERY_STRING} >> その他の CGI のリクエスト情報は、 L<Tripletail::InputFilter>
が読み取り、 L<Tripletail::Form> オブジェクトを生成する。得られたリクエスト情報は
C<$CGI> オブジェクトか L<< $TL->CGI|/"CGI" >> メソッドで取得出来る。


=head2 Main 関数

リクエスト一回毎に呼ばれる関数。この関数の中で CGI プログラムは入出力を行う。
L</"FastCGI モード"> 以外では一度のプロセスの起動で一度しか呼ばれない。


=head2 フック

L<< $TL->setHook|/"setHook" >> メソッドを用いてフックを掛ける事が出来る。

=over 4

=item C<init>

L</"startCgi"> もしくは L</"trapError"> が呼ばれ、最初に L</"Main 関数"> が
呼ばれる前。 FastCGI の場合は最初の1回だけ呼ばれる。

=item C<initRequest>

L</"startCgi"> 利用時は、リクエストを受け取った直後、フォームがデコードされる前に呼ばれる。
リクエストごとに呼び出される。

L</"trapError"> 利用時は L</"postRequest"> フックの前に呼び出される。

=item C<preRequest>

L</"startCgi"> 利用時は、フォームをデコードした後、L</"Main 関数"> が呼ばれる前に呼ばれる。
リクエストごとに呼び出される。
ただし、フォームのデコード処理に失敗した場合、L<"/preRequest"> は実行されずにリクエスト処理が終了する。

L</"trapError"> 利用時は L</"initRequest"> フックの後、L</"Main 関数"> が呼ばれる前に呼ばれる。

=item C<postRequest>

L</"startCgi"> 利用時は、L</"Main 関数"> の処理を終えた後、コンテンツの出力を行ってから呼び出される。
リクエストごとに呼び出される。
ただし、フォームのデコード処理に失敗した場合、L</"postRequest"> は実行されずにリクエスト処理が終了する。

L</"trapError"> 利用時は L</"Main 関数"> が呼ばれた後に呼び出される。

=item C<term>

最後に L</"Main 関数"> が呼ばれた後。C<term>フック呼出し後に L</"startCgi">
もしくは L</"trapError"> が終了する。
FastCGI の場合は最後の1回だけ呼ばれる。

=back


=head2 METHODS

=head3 よく使うもの

=head4 C<< startCgi >>

  $TL->startCgi(
    -main        => \&Main,    # メイン関数
    -DB          => 'DB',      # DBを使う場合，iniのグループ名を指定
    -Session => 'Session',     # Sessionを使う場合、iniのグループ名を指定
  );

CGI を実行する為の環境を整えた上で、 L</"Main 関数"> を実行する。
L</"Main 関数"> がdie した場合は、エラー表示 HTML が出力される。

C<DB> は、次のように配列へのリファレンスを渡す事で、複数指定可能。

  $TL->startCgi(
    -main => \&Main,
    -DB   => ['DB1', 'DB2'],
  );

C<Session> は、次のように配列へのリファレンスを渡す事で、複数指定可能。

  $TL->startCgi(
    -main        => \&Main,
    -DB          => 'DB',
    -Session => ['Session1', 'Session2'],
  );

通常のスクリプトを書く場合は L</trapError> を参照.

=head4 C<< CGI >>

  $TL->CGI
  $CGI

リクエストを受け取った L<Tripletail::Form> オブジェクトを返す。
また、このオブジェクトは startCgi メソッドの呼び出し元パッケージに export される。

このメソッドがC<undef>でない値を返すのは、 L</"preRequest"> フックが呼ばれる
直前から L</"postRequest"> フックが呼ばれた直後までである。

=head4 C<< dispatch >>

  $result = $TL->dispatch($value, %params)

  $params{default} = $scalar.
  $params{onerror} = \&error.
  $params{args}    = \@args.

'Do' と $value を繋げた関数名の関数を呼び出す。
$valueがC<undef>の場合、 default を指定していた場合、default に設定される。
$value は大文字で始まらなければならない。

args 引数が指定されていた場合、関数にその内容を渡す。
指定されていなければ関数は引数なしで呼び出される。
(0.44以降)

C<onerror> が未設定で関数が存在しなければ C<undef>、存在すれば1を返す。

C<onerror> が設定されていた場合、関数が存在しなければ C<onerror> で設定された関数が呼び出される。

  例:
  package Foo;
  
  sub main {
      my $what = 'Foo';
      $TL->dispatch($what, default => 'Foo', onerror => \&DoError);
  }
  
  sub DoFoo {
      ...
  }

  sub DoError {
      ...
  }

=head4 C<< print >>

  $TL->print($str)

コンテンツデータを出力する。L</"startCgi"> から呼ばれた L</"Main 関数"> 内
のみで使用できる。ヘッダは出力できない。

フィルタによってはバッファリングされる場合もあるが、
基本的にはバッファリングされない。

=head4 C<< location >>

  $TL->location('http://example.org/')

CGI モードの時、指定されたURLへリダイレクトする。
このメソッドはあらゆる出力の前に呼ばなくてはならない。 

また、出力フィルタが L<Tripletail::Filter::HTML> か L<Tripletail::Filter::MobileHTML>
の場合のみ利用できる。

=head4 C<< eval >>

  $TL->eval(sub {
                # Statements which may throw...
              });
  if ($@) {
      ....
  }

引数として与えられたサブルーチンを実行するが、その実行中は Tripletail
によるエラー処理を無効にする。サブルーチンが正常な動作の範囲内として
die する事が判っている場合に、エラー処理のコストを減らし、且つ C<< $@
>> が書き換えられる事を防ぐために使用する。

=head3 変換処理

=head4 C<< escapeTag >>

  $result = $TL->escapeTag($value)

&E<lt>E<gt>"' の文字をエスケープ処理した文字列を返す。

=head4 C<< unescapeTag >>

  $result = $TL->unescapeTag($value)

&E<lt>E<gt>"'&#??;&#x??; にエスケープ処理された文字を元に戻した文字列を返す。

=head4 C<< escapeJs >>

  $result = $TL->escapeJs($value)

'"\ の文字を \ を付けてエスケープし，'\r' '\n' について '\\r' '\\n' に置き換える。

=head4 C<< unescapeJs >>

  $result = $TL->unescapeJs($value)

escapeJs した文字列を元に戻す。

=head4 C<< escapeJsString >>

  $result = $TL->escapeJsString($value)

JavaScriptの文字列コードになるようにエスケープする。
その際には、html内にJavaScriptを埋め込んだ際に終端と誤認される「E<lt>/scriptE<gt>」「--E<gt>」を考慮する。
例えば、

  $TL->escapeJsString("ab\"cd </script> def")

を評価すると、

  '"ab\"cd </scr"+"ipt> def"'

が得られる。

=head4 C<< unescapeJsString >>

  $result = $TL->unescapeJsString($value)

escapeJsString した文字列を元に戻す。

=head4 C<< encodeURL >>

  $result = $TL->encodeURL($value)

文字列をURLエンコードした結果を返す。

=head4 C<< decodeURL >>

  $result = decodeURL($value)

URLエンコードを解除し元に戻した文字列を返す。

=head4 C<< escapeSqlLike >>

  $result = $TL->escapeSqlLike($value)

% _ \ の文字を \ でエスケープ処理した文字列を返す。

=head4 C<< unescapeSqlLike >>

  $result = $TL->unescapeSqlLike($value)

\% \_ \\ にエスケープ処理された文字を元に戻した文字列を返す。

=head4 C<< charconv >>

  $str = $TL->charconv($str, $from, $to);
  
  $str = $TL->charconv($str, 'auto' => 'UTF-8');

文字コード変換を行う。
基本的に L<Unicode::Japanese> を利用するが、サポートしていない
文字コードの場合は L<Encode> を使用する。

C<$from> が省略された場合は C<'auto'> に、
C<$to> が省略された場合は C<'UTF-8'> になる。

指定できる文字コードは、 UTF-8，Shift_JIS，EUC-JP，ISO-2022-JP のほか、
L<Unicode::Japanese>、L<Encode> がサポートしているものが使用できる。

=head4 C<< parsePeriod >>

  $TL->parsePeriod('10hour 30min')

時間指定文字列を秒数に変換する。小数点が発生した場合は切り捨てる。
L</"度量衡"> を参照。

=head4 C<< parseQuantity >>

  $TL->parseQuantity('100mi 50ki')

量指定文字列を元の数に変換する。
L</"度量衡"> を参照。

=head3 インスタンス生成取得

=head4 C<< getDB >>

  $DB = $TL->getDB($group)

L<Tripletail::DB> オブジェクトを取得。

=head4 C<< newDB >>

  $DB = $TL->newDB($group)

L<Tripletail::DB> オブジェクトを作成。

=head4 C<< newForm >>

L<Tripletail::Form> オブジェクトを作成。

=head4 C<< newTemplate >>

L<Tripletail::Template> オブジェクトを作成。

=head4 C<< getSession >>

L<Tripletail::Session> オブジェクトを取得。

=head4 C<< newValidator >>

L<Tripletail::Validator> オブジェクトを生成。

=head4 C<< newValue >>

L<Tripletail::Value> オブジェクトを作成。

=head4 C<< newDateTime >>

L<Tripletail::DateTime> オブジェクトを作成。

=head4 C<< newPager >>

L<Tripletail::Pager> オブジェクトを作成。

=head4 C<< getCsv >>

L<Tripletail::CSV> オブジェクトを取得。

=head4 C<< newTagCheck >>

L<Tripletail::TagCheck> オブジェクトを作成。

=head4 C<< newHtmlFilter >>

L<Tripletail::HtmlFilter> オブジェクトを作成。

=head4 C<< newHtmlMail >>

L<Tripletail::HtmlMail> オブジェクトを作成。

=head4 C<< newMail >>

L<Tripletail::Mail> オブジェクトを作成。

=head4 C<< newIni >>

L<Tripletail::Ini> オブジェクトを作成。

=head4 C<< getCookie >>

L<Tripletail::Cookie> オブジェクトを取得。

=head4 C<< getRawCookie >>

L<Tripletail::RawCookie> オブジェクトを取得。

=head4 C<< newSendmail >>

L<Tripletail::Sendmail> オブジェクトを作成。

=head4 C<< newSerializer >>

L<Tripletail::Serializer> オブジェクトを作成。

=head4 C<< newSMIME >>

L<Crypt::SMIME> オブジェクトを作成。

=head4 C<< getFileSentinel >>

L<Tripletail::FileSentinel> オブジェクトを取得。

=head4 C<< getMemorySentinel >>

L<Tripletail::MemorySentinel> オブジェクトを取得。

=head4 C<< newMemCached >>

L<Tripletail::MemCached> オブジェクトを生成。

=head3 その他

=head4 C<< INI >>

  $TL->INI

C<< use Tripletail qw(filename.ini); >> で読み込まれた L<Tripletail::Ini> を返す。

=head4 C<< trapError >>

  $TL->trapError(
    -main => \&Main, # メイン関数
    -DB   => 'DB',   # DBを使う場合，iniのグループ名を指定
  );

環境を整え、 L</"Main 関数"> を実行する。
L</"Main 関数"> がdie した場合は、エラー内容が標準エラーへ出力される。

L</"startCgi"> と同様に、C<DB> には配列へのリファレンスを渡す事も出来る。

=head4 C<< fork >>

  if (my $pid = $TL->fork) {
      # parent
  }
  else {
      # child
  }

FastCGI 環境を考慮しながら fork を実行する。 FastCGI 環境でない場合は通
常通りに fork する。fork に失敗した場合は die する。

通常は perl 組込み関数である fork を使用しても問題無いが、 FastCGI 環境
では正常に動作しない為、Tripletail アプリケーションは常に fork でなく
C<< $TL->fork >> を使用する事が推奨される。

=head4 C<< log >>

  $TL->log($group => $log)

ログを記録する。グループとログデータの２つを受け取る。

第一引数のグループは省略可能。
ログデータがリファレンスだったときは Data::Dumper によってダンプされる。

ログにはヘッダが付けられ、ヘッダは「時刻(epoch値の16進数8桁表現) プロセス ID の16進数4桁表現 FastCGI のリクエスト回数の16進数4桁表現 [グループ]」の形で付けられる。

=head4 C<< setContentFilter >>

  $TL->setContentFilter($classname, %option)
  $TL->setContentFilter([$classname, $priority], %option)
  $TL->setContentFilter('Tripletail::Filter::HTML', charset => 'Shift_JIS')
  $TL->setContentFilter(
      'Tripletail::Filter::CSV', charset => 'Shift_JIS', filename => 'テストデータ.csv')

L</"出力フィルタ"> を設定する。
全ての出力の前に実行する必要がある。
２番目の書式では、プライオリティを指定して独自のコンテンツフィルタを
追加できる。省略時は優先度は1000となる。小さい優先度のフィルタが先に、
大きい優先度のフィルタが後に呼ばれる。同一優先度のフィルタが既に
セットされているときは、以前のフィルタ設定は解除される。

返される値は、指定された L<Tripletail::Filter> のサブクラスのインスタンスである。

設定したフィルタは、L</"preRequest"> 実行後のタイミングで保存され、
L</"postRequest"> のタイミングで元に戻される。従って、L</"Main 関数">内
で setContentFilter を実行した場合、その変更は次回リクエスト時に持ち越
されない。

=head4 C<< getContentFilter >>

  $TL->getContentFilter($priority)

指定されたプライオリティのフィルタを取得する。省略時は1000となる。

=head4 C<< removeContentFilter >>

  $TL->removeContentFilter($priority)

指定されたプライオリティのフィルタを削除する。省略時は1000となる。
フィルタが１つもない場合は、致命的エラーとなり出力関数は使用できなくなる。

=head4 C<< getLogHeader >>

  my $logid = $TL->getLogHeader

ログを記録するときのヘッダと同じ形式の文字列を生成する。
「時刻(epoch値の16進数8桁表現) プロセス ID の16進数4桁表現 FastCGI のリクエスト回数の16進数4桁表現」の形の文字列が返される。

=head4 C<< setHook >>

  $TL->setHook($type, $priority, \&func)

指定タイプの指定プライオリティのフックを設定する。
既に同一タイプで同一プライオリティのフックが設定されていた場合、
古いフックの設定は解除される。

C<type> は、L</"init">, L</"term">, L</"initRequest">, L</"preRequest">, L</"postRequest">
の４種類が存在する。

なお、1万の整数倍のプライオリティは Tripletail 内部で使用される。アプリ
ケーション側で不用意に用いるとフックを上書きしてしまう可能性があるので
注意する。

=head4 C<< removeHook >>

  $TL->removeHook($type, $priority)

指定タイプの指定プライオリティのフックを削除する。

=head4 C<< setInputFilter >>

  $TL->setInputFilter($classname, %option)
  $TL->setInputFilter([$classname, $priority], %option)

L</"入力フィルタ"> を設定する。
L</"startCgi"> の前に実行する必要がある。

返される値は、指定された L<Tripletail::InputFilter> のサブクラスのインスタンスである。

=head4 C<< getInputFilter >>

  $TL->getInputFilter($priority)

=head4 C<< removeInputFilter >>

  $TL->removeInputFilter($priority)

=head4 C<< sendError >>

  $TL->sendError(title => "タイトル", error => "エラー")

L<ini|Tripletail::Ini> で指定されたアドレスにエラーメールを送る。
設定が無い場合は何もしない。

=head4 C<< readFile >>

  $data = $TL->readFile($fpath);

ファイルを読み込む。文字コード変換をしない。
ファイルロック処理は行わないので、使用の際には注意が必要。

=head4 C<< readTextFile >>

  $data = $TL->readTextFile($fpath, $coding);

ファイルを読み込み、 UTF-8 に変換する。
ファイルロック処理は行わないので、使用の際には注意が必要。

C<$coding> が省略された場合は C<'auto'> となる。

=head4 C<< writeFile >>

  $TL->writeFile($fpath, $fdata, $fmode);

ファイルにデータを書き込む。文字コード変換をしない。
ファイルロック処理は行わないので、使用の際には注意が必要。

C<$fmode> が0ならば、上書きモード。
C<$fmode> が1ならば、追加モード。

省略された場合は上書きモードとなる。

=head4 C<< writeTextFile >>

  $TL->writeTextFile($fpath, $fdata, $fmode, $coding);

ファイルにデータを書き込む。C<$fdata> を UTF-8 と見なし、指定された文字コードへ変換を行う。
ファイルロック処理は行わないので、使用の際には注意が必要。

C<$fmode> が0ならば、上書きモード。
C<$fmode> が1ならば、追加モード。

省略された場合は上書きモードとなる。

C<$coding> が省略された場合、 UTF-8 として扱う。

=head4 C<< watch >>

  $TL->watch(sdata => \$sdata, $reclevel);
  $TL->watch(adata => \@adata, $reclevel);
  $TL->watch(hdata => \%hdata, $reclevel);

指定したスカラー、配列、ハッシュデータの更新をウォッチし、ログに出力する。
第1引数で変数名を、第2引数で対象変数へのリファレンスを渡す。

第2引数はウォッチ対象の変数に、リファレンスが渡された場合に、
そのリファレンスの先を何段階ウォッチするかを指定する。デフォルトは0。

スカラー、配列、ハッシュ以外のリファレンスが代入された場合はエラーとなる。

また、再帰的にウォッチする場合、変数名は親の変数名を利用して自動的に設定される。

=head4 C<< dump >>

  $TL->dump(\$data);
  $TL->dump(\$data, $level);
  $TL->dump(DATA => \$data);
  $TL->dump(DATA => \$data, $level);

第2引数に変数へのリファレンスを渡すと，その内容を Data::Dumper でダンプし、
第1引数のグループ名で $TL->log を呼び出す。

第1引数のグループ名は省略可能。

第3引数で、リファレンスをどのくらいの深さまで追うかを指定することが出来る。
指定しなければ全て表示される。

=head4 C<< setCacheFilter >>

  $TL->setCacheFilter($form)
  $TL->setCacheFilter($form, $charset)
  $TL->setCacheFilter($hashref)
  $TL->setCacheFilter($hashref, $charset)

L</printCacheUnlessModified> と L</setCache> を利用する際に使用する。
第1引数で渡された L<Tripletail::Form> オブジェクトのキーが出力文字列中に存在している場合、値に置換する。

L<Tripletail::Form>オブジェクトの代わりにハッシュのリファレンスを渡すことも出来る。
ハッシュのリファレンスを渡した場合は、$TL->newForm($hashref) した結果のフォームオブジェクトを追加する。

第2引数は、第1引数で指定した文字列を UTF-8 から変換する際の文字コードを指定する。
省略可能。

使用可能なコードは次の通り。
UTF-8 ，Shift_JIS，EUC-JP，ISO-2022-JP

デフォルトはShift_JIS。

=head4 C<< printCacheUnlessModified >>

  $bool = $TL->printCacheUnlessModified($key, $status)

第1引数で割り当てられたキーがメモリ上にキャッシュされているかを調べる。
利用するには、 memcached が必須となる。

第2引数が304の場合、304レスポンスを送る動作を行う。200の場合、200レスポンスを送る動作を行う。
省略可能。

デフォルトは304。

この関数は次のような動作を行っている。

1. memcached からキーに割り当てられたキャッシュデータを読み込む。
データが無ければ、1を返す。

2.キャッシュデータの保存された時間と前回アクセスされた時間を比較し、
キャッシュデータが新しければキャッシュデータを出力し、C<undef>を返す。

3.アクセスされた時間が新しければ、304レスポンスを出力し、C<undef>を返す。
（第2引数が304の場合。200の場合はキャッシュデータを出力する）

この関数からC<undef>を返された場合、以後出力を行う操作を行ってはならない。

=head4 C<< setCache >>

  $TL->setCache($key, $priority)


第1引数で割り当てられたキーに対して出力される内容をメモリ上にキャッシュする。
また、Last-Modified ヘッダを出力する。
printCacheUnlessModified より後で実行する必要がある。
利用するには、 memcached が必須となる。

第2引数には、L<Tripletail::Filter::MemCached>への優先度を記述する。省略可能。
デフォルトは1500。

Tripletail::Filter::MemCachedは必ず最後に実行する必要性があるため、
1500以上の優先度で設定するフィルタが他にある場合は手動で設定する必要がある。

=head4 C<< deleteCache >>

  $TL->deleteCache($key)

第1引数で割り当てられたキーのキャッシュを削除する。
利用するには、 memcached が必須となる。

なお、setCacheの後にdeleteCacheを実行しても、setCacheでのメモリへの書き込みは、
処理の最後に行われるので、deleteCacheは反映されない。

本関数の使い方としては、キャッシュの内容を含んでいるデータを更新した場合に
該当するキャッシュを削除するように使用する。
それにより、次回アクセス時に最新の情報が出力される。

=head4 C<< getDebug >>

=head4 C<< newError >>

内部用メソッド。


=head2 Ini パラメータ

グループ名は常に B<TL> でなければならない。

例:

  [TL]
  logdir = /home/www/cgilog/
  errortemplate = /home/www/error.html
  errortemplatecharset = Shift_JIS

=over 4

=item C<maxrequestsize>

  maxrequestsize = 16M 500K

最大リクエストサイズ。但しファイルアップロードの分を除く。デフォルトは8M。

=item C<maxfilesize>

  maxfilesize = 100M

一回のPOSTでアップロード可能なファイルサイズの合計。デフォルトは8M。ファ
イルのサイズは C<maxrequestsize> とは別にカウントされ、ファイルでないもの
については C<maxrequestsize> の値が使われる。

=item C<fault_handler>

  fault_handler = Name::Of::Handler

startCgi での最大リクエストサイズ若しくは
アップロード可能なファイルサイズを超えたときに
例外ハンドラとする関数名。
モジュールは必要なら自動でロードされる。

 # [TL]
 # fault_handler = MyApp::FaultHandler
 package MyApp;
 sub FaultHandler
 {
   my $pkg = shift;
   my $err = shift;
   my $status = ref($err) && $err->{http_status_line};
   $status ||= '500 Internal Server Error';
   
   print "Status: $status\r\n";
   print "Content-Type: text/plain; charset=utf-8\r\n";
   print "\r\n";
   print "error: $err\n";
 }

(C<http_status_line> は 0.42 以降でサポート)

=item C<logdir>

  logdir = /home/www/cgilog/

ログの出力ディレクトリ。

=item C<tempdir>

  tempdir = /tmp

一時ファイルを置くディレクトリ。このパラメータの指定が無い時、アップロー
ドされたファイルは全てメモリ上に置かれるが、指定があった場合は指定され
たディレクトリに一時ファイルとして置かれる。一時ファイルを作る際には、
ファイルを open した直後に unlink する為、アプリケーション側でファイル
ハンドルを閉じたりプロセスを終了したりすると、作られた一時ファイルは直
ちに自動で削除される。

=item C<errormail>

  errormail = null@example.org%Sendmail

sendErrorや、エラー発生時にメールを送る先を指定する。
C<アカウント名@ドメイン名%inigroup> 、の形式で指定する。
inigroup に  L<Tripletail::Sendmail> クラスで使用する inigroup を指定する。
inigroup が省略されると C<'Sendmail'> が使われる。

=item C<errormailtype>

  errormailtype = error file-update memory-leak

どのような事象が発生した時に errormail で指定された先にメールを送るか。
以下の項目をスペース区切りで任意の数だけ指定する。
デフォルトは 'error memory-leak' である。

=item C<errormail_subject_len>

  errormail_subject_len = 80

エラー発生時に送られるメールの表題の最大長。長過ぎるとメール送信に失敗
する場合がある。デフォルトは 80 バイト。

=over 4

=item C<error>

エラーが発生した時にメールを送る。
メールの内容にはスタックトレース等が含まれる。

=item C<file-update>

L<Tripletail::FileSentinel> が監視対象のファイルの更新を検出した時にメールを送る。
メールの内容には更新されたファイルやその更新時刻が含まれる。

=item C<memory-leak>

L<Tripletail::MemorySentinel> がメモリリークの可能性を検出した時にメールを送る。
メールの内容にはメモリの使用状況が含まれる。

=back

=item C<errorlog>

  errorlog = 1

エラー発生時にログに情報を残すかどうかを指定する。
1 が指定されればエラー情報を残す。
2 が指定されれば、エラー情報に加え、 CGI のリクエスト内容も残す（startCgi内でのエラーのみ）。
3 が指定されれば、ローカル変数内容を含んだ詳細なエラー情報に加えて（但し PadWalker が必要）、 CGI のリクエスト内容も残す。
0 であれば情報を残さない。
デフォルトは 1。

=item C<fcgilog>

  fcgilog = 1

FCGI 関連の動作をログに記録するかどうかを指定する。
1 が指定されれば記録する。
0 であれば記録しない。
デフォルトは 0。

=item C<memorylog>

  memorylog = full

リクエスト毎にメモリ消費状況をログに残すかどうかを指定する。
'leak', 'full' のどちらかから選ぶ。
'leak' の場合は、メモリリークが検出された場合のみログに残す。
'full' の場合は、メモリリークの検出とは無関係に、リクエスト毎にログに残す。
デフォルトは 'leak' 。

=item C<filelog>

  filelog = full

ファイルの更新の監視状況をログに残すかどうかを指定する。
'C<update>', 'C<full>' のどちらかから選ぶ。
'C<update>' の場合は、ファイルが更新された場合のみログに残す。
'C<full>' の場合は、ファイルの監視を開始した際にもログに残す。
デフォルトは 'C<update>'。

=item C<trap>

  trap = die

エラー処理の種類。'C<none>', 'C<die>'，'C<diewithprint>' から選ぶ。デフォルトは'C<die>'。

=over 4

=item C<none>

エラートラップを一切しない。

=item C<die>

L</"Main 関数"> がdie した場合にエラー表示。それ以外の場所ではトラップしない。warnは見逃す。

=item C<diewithprint>

L</"Main 関数"> がdie した場合にエラー表示。L</"Main 関数"> 以外でdie した場合は、ヘッダと共にエラー内容をテキストで表示する。warnは見逃す。

=back

=item C<stacktrace>

  stacktrace = full

エラー発生時に表示するスタックトレースの種類。'none' の場合は、スタック
トレースを一切表示しない。'C<onlystack>' の場合は、スタックトレースのみを
表示する。'full' の場合は、スタックトレースに加えてソースコード本体並び
に各フレームに於けるローカル変数の一覧をも表示する。デフォルトは
 'C<onlystack>'。

但しローカル変数一覧を表示するには L<PadWalker> がインストールされてい
なければならない。

注意: 'full' の状態では、C<stackallow> で許された全てのユーザーが、
ブラウザから全てのソースコード及び ini
ファイルの中身を読む事が出来る点に注意すること。

=item C<stackallow>

  stackallow = 192.168.0.0/24

C<stacktrace> の値が 'none' でない場合であっても、C<stackallow> で指定された
ネットマスクに該当しない IP からの接続である場合には、スタックトレース
を表示しない。マスクは空白で区切って複数個指定する事が可能。
デフォルトは全て禁止。

=item C<maxrequestcount>

  maxrequestcount = 100

FastCGI モード時に、1つのプロセスで何回まで処理を行うかを設定する。
0を設定すれば回数によってプロセスが終了することはない。
デフォルトは0。

=item C<errortemplate>

  errortemplate = /home/www/error.html

エラー発生時に、通常のエラー表示ではなく、指定された
テンプレートファイルを表示する。

=item C<errortemplatecharset>

  errortemplatecharset = Shift_JIS

errortemplate指定時に、エラーメッセージを返す際の charset を指定する。

UTF-8 ， Shift_JIS ， EUC-JP ， ISO-2022-JP が指定できる。デフォルトは UTF-8 。

=item C<outputbuffering>

  outputbuffering = 0

startCgi メソッド中で出力をバッファリングするかどうか。
0 だとバッファリングを行わず、
1 だとバッファリングを行う。
デフォルトは0。

バッファリングしない場合、print した内容はすぐに表示されるが、少しでも表示を行った後にエラーが発生した場合は、エラーテンプレートが綺麗に表示されない。

バッファリングを行った場合、print した内容はリクエスト終了時まで表示されないが、処理中にエラーが発生した場合、出力内容は破棄され、エラーテンプレートの内容に差し替えられる。
また、Content-Length ヘッダが付与される。

L<Tripletail::Filter::MobileHTML> を利用した場合、C<outputbuffering> は1にセットされる。

=for COMMENT
  有効にすると Content-Filter への中継も行われなくなる.
  この際, CGI 終了時に１つのデータでprintされ, 続けてflushされる.

=item C<allow_mutable_input_cgi_object>

  allow_mutable_input_cgi_object = 1

非推奨. 互換のためのパラメータ. (0.40以降)

C<$TL->CGI> で返される CGI 入力値を保持しているオブジェクトの
const 化を行わないようにする.

=item C<compat_no_trap_for_cgi_internal_error>

  compat_no_trap_for_cgi_internal_error = 1

互換のためのパラメータ. (0.42以降)

CGI モード動作時の startCgi 外のエラーに対する
エラー画面の表示を抑制する.
(httpd による通常の Internal Server Error 画面になります)

=item C<compat_form_getfilename_returns_fullpath>

互換のためのパラメータ. (0.45以降)

1 (真)を設定することで L<$form->getFileName|Tripletail::Form/getFileName> が
フルパスを返す振る舞いに戻す。
デフォルト値は偽で, getFileName はベース名部分のみを返す.

新しいコードではフルパスが欲しいときには
L<$form->getFullFileName|Tripletail::Form/getFullFileName> を推奨。

=item C<command_add_processname>

  command_add_processname = 1

FastCGI で処理する際に、プロセス名に各種情報を表示するかを指定します。(0.46以降)

0 だとプロセス名を変更しません。
1 だとプロセス名を変更します。
デフォルトは0です。

1 にすると「perl リクエスト処理回数 (処理内容) スクリプト名」となります。

処理内容には、FastCGI 時に fcgi run、fcgi wait が表示されます。
また、C<$TL->dispatch> を使用した際は、分岐先のコマンドが追加されます。

プロセス名は、起動時のプロセス名の長さより長くすることが出来ないため、
起動時の状況によっては全て表示されないことがあります。


=back

=head2 度量衡

=head3 時間指定

各種タイムアウト時間，セッションのexpiresなど、
時間間隔は以下の指定が可能とする。
数値化には L</parsePeriod> を使用する. 

単位は大文字小文字を区別しない。

=over 4

=item 数値のみ

秒数での指定を表す。

=item 数値＋ 'sec' or 'second' or 'seconds'

秒での指定を表す。[×1]

=item 数値＋ 'min' or 'minute' or 'minutes'

分での指定を表す。[×60]

=item 数値＋ 'hour' or 'hours'

時間での指定を表す。[×3600]

=item 数値＋ 'day' or 'days'

日数での指定を表す。[×24*3600]

=item 数値＋ 'mon' or 'month' or 'months'

月での指定を表す。１月＝30.436875日として計算する。 [×30.436875*24*3600]

=item 数値＋ 'year' or 'years'

年での指定を表す。１年＝365.2425日として計算する。 [×365.2425*24*3600]

=back

=head3 量指定

メモリサイズ、文字列サイズ等、大きさを指定する場合には、
以下の指定が可能とする。英字の大文字小文字は同一視する。

数値化には L</parseQuantity> を使用する. 

=head4 10進数系

=over 4

=item 数値のみ

そのままの数を表す。

=item 数値＋ 'k'

数値×1000の指定を表す。[×1,000]

=item 数値＋ 'm'

数値×1000^2の指定を表す。[×1,000,000=×1,000^2]

=item 数値＋ 'g'

数値×1000^3の指定を表す。[×1,000,000,000=×1,000^3]

=item 数値＋ 't'

数値×1000^4の指定を表す。[×1,000,000,000,000=×1,000^4]

=item 数値＋ 'p'

数値×1000^5の指定を表す。[×1,000,000,000,000,000=×1,000^5]

=item 数値＋ 'e'

数値×1000^6の指定を表す。[×1,000,000,000,000,000,000=×1,000^6]

=back

=head4 2進数系

=over 4

=item 数値＋ 'Ki'

数値×1024の指定を表す。[×1024=2^10]

=item 数値＋ 'Mi'

数値×1024^2の指定を表す。[×1024^2=2^20]

=item 数値＋ 'Gi'

数値×1024^3の指定を表す。[×1024^3=2^30]

=item 数値＋ 'Ti'

数値×1024^4の指定を表す。[×1024^4=2^40]

=item 数値＋ 'Pi'

数値×1024^5の指定を表す。[×1024^5=2^50]

=item 数値＋ 'Ei'

数値×1024^6の指定を表す。[×1024^6=2^60]

=back

=head1 SAMPLE

 perldoc -u Tripletail |  podselect -sections SAMPLE | sed -e '1,4d' -e 's/^ //'


 # master configurations.
 #
 [TL]
 logdir=/home/project/logs/error
 errormail=errors@your.address
 errorlog=2
 trap=diewithprint
 stackallow=0.0.0.0/0
 
 [TL:SmallDebug]
 stacktrace=onlystack
 outputbuffering=1
 
 [TL:Debug]
 stacktrace=full
 outputbuffering=1
 
 [TL:FullDebug]
 stacktrace=full
 outputbuffering=1
 stackallow=0.0.0.0/0
 
 # database configrations.
 #
 [DB]
 type=mysql
 namequery=1
 tracelevel=0
 AllTransaction=DBALL
 defaultset=AllTransaction
 [DBALL]
 dbname=
 user=
 password=
 #host=
 
 [DB:SmallDebug]
 
 [DB:Debug]
 
 [DB:FullDebug]
 tracelevel=2
 
 # debug configrations.
 #
 [Debug]
 enable_debug=0
 
 [Debug:SmallDebug]
 enable_debug=1
 
 [Debug:Debug]
 enable_debug=1
 request_logging=1
 content_logging=1
 warn_logging=1
 db_profile=1
 popup_type=single
 template_popup=0
 request_popup=1
 db_popup=0
 log_popup=1
 warn_popup=1
 
 [Debug:FullDebug]
 enable_debug=1
 request_logging=1
 content_logging=0
 warn_logging=1
 db_profile=1
 popup_type=single
 template_popup=1
 request_popup=1
 db_popup=1
 log_popup=1
 warn_popup=1
 location_debug=1
 
 # misc.
 #
 [SecureCookie]
 path=/
 secure=1
 
 [Session]
 mode=https
 securecookie=SecureCookie
 timeout=30min
 updateinterval=10min
 dbgroup=DB
 dbset=AllTransaction
 
 # user data.
 # you can read this data:
 # $val = $TL->INI->get(UserData=>'roses');
 #
 [UserData]
 roses=red
 violets=blue
 sugar=sweet

=head1 SEE ALSO

=over 4

=item L<Tripletail::Cookie>

=item L<Tripletail::DB>

=item L<Tripletail::Debug>

CGI 向けデバッグ機能。

リクエストや応答のログ記録、デバッグ情報のポップアップ表示、他。

=item L<Tripletail::Filter>

=item L<Tripletail::FileSentinel>

=item L<Tripletail::Form>

=item L<Tripletail::HtmlFilter>

=item L<Tripletail::HtmlMail>

=item L<Tripletail::Ini>

=item L<Tripletail::InputFilter>

=item L<Tripletail::Mail>

=item L<Tripletail::MemorySentinel>

=item L<Tripletail::Pager>

=item L<Tripletail::RawCookie>

=item L<Tripletail::Sendmail>

=item L<Crypt::SMIME>

=item L<Tripletail::TagCheck>

=item L<Tripletail::Template>

=item L<Tripletail::Session>

=item L<Tripletail::Value>

=item L<Tripletail::Validator>

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: C<tl@tripletail.jp>

HP : http://tripletail.jp/

=back

=cut
