# -----------------------------------------------------------------------------
# Tripletail::Session - セッションの管理を行う
# -----------------------------------------------------------------------------
package Tripletail::Session;
use strict;
use warnings;
use Digest::SHA qw(hmac_sha1_hex);
use Tripletail;
use Hash::Util qw(lock_hash);

sub _POST_REQUEST_HOOK_PRIORITY() { -2_000_000 } # 順序は問わない

# このクラスは次のようなクッキーまたはクエリにデータを保存する。
# * HTTP側  : クッキー名 SID + グループ名 / クエリ名 SID + グループ名
# * HTTPS側 : クッキー名 SIDS + グループ名 / クエリ名 SIDS + グループ名

# -------------------------------------------------------
# セッションデータの入出力は次のようになる。
#
# [出力時]
#   [1: クッキーを使う場合]
#     Tripletail::FilterがSet-Cookie:ヘッダを出力する。
#     この時、iniパラメータ"cookie" / "securecookie"で指定されたグループ名のTripletail::Cookieが使われる。
#   [2: クエリを使う場合]
#     Tripletail::Filterが$SAVEに加える。
#
# [入力時]
#   [1: クッキーを使う場合]
#     Tripletail::InputFilterがdecodeCgi中に$TL->getCookieし、その中にセッションデータがあり、
#     且つTripletail::Sessionが有効になっていれば、$TL->getSession->_setSessionDataする。
#   [2: クエリを使う場合]
#     Tripletail::InputFilterがdecodeCgi中にクエリ内にセッションデータを見付けた場合、
#     Tripletail::Sessionが有効になっているなら、$TL->getSession->_setSessionDataする。

our %_instance;

my %BACKEND_OF = (
    mysql  => 'Tripletail::Session::MySQL',
    pgsql  => 'Tripletail::Session::PgSQL',
    sqlite => 'Tripletail::Session::SQLite',
   );
lock_hash(%BACKEND_OF);

1;

sub isHttps {
	$ENV{HTTPS} and $ENV{HTTPS} eq 'on';
}

sub get {
	my $this = shift;

	if(!defined($this->{sid})) {
		$this->_createSid;
	}

	$this->{sid};
}

sub renew {
	my $this = shift;

	$this->discard;
	$this->get;
}

sub discard {
	my $this = shift;

	if(defined($this->{sid})) {
        $this->_deleteSid($this->{sid});

        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__,
                     "Removed the session ID [$this->{sid}] on the DB".
                       " [$this->{dbgroup}][$this->{sessiontable}].");
        }
	}
	$this->__reset;

	$this;
}

sub setValue {
	my $this = shift;
	my $value = shift;

	if((!$this->isHttps) && ($this->{mode} eq 'double' || $this->{mode} eq 'https')) {
		die __PACKAGE__."#setValue: we can't modify session while we are using '$this->{mode}' mode but not in the https connection.".
			" ($this->{mode}モードの場合はhttps接続中でのみセッション内容を変更できます)\n";
	}

	if($this->{setvaluewithrenew}) {
		$this->discard;
		$this->{data} = $value;
		$this->get;
	} else {
		if(defined($this->{sid})) {
			$this->{data} = $value;
			$this->{updatetime} = 0; # アップデートを行わせる
			$this->_updateSession;
		} else {
			$this->{data} = $value;
			$this->get;
		}
	}

	$this;
}

sub getValue {
	my $this = shift;

	$this->{data};
}

sub getSessionInfo {
	my $this = shift;
	my $issecure = shift;

	if(!defined($issecure)) {
		$issecure = $this->isHttps
	}

	(($issecure ? 'SIDS' : 'SID') . $this->{group}, $this->{sid}, ($issecure ? $this->{checkvalssl} : $this->{checkval}));
}

sub _createSid {
	my $this = shift;

	# ※MySQLのunsigned bigint時なら19桁だが、pgsqlではunsignedがないため、18桁までが上限。
	# 64bit整数(unsigned)は 1844 6744 0737 0955 1615 まで
	# 64bit整数(signed)は    922 3372 0368 5477 5807 まで
	$this->{checkval}    = '_' x 18;
	$this->{checkval}    =~ s/_/int(rand(10))/eg;
	$this->{checkvalssl} = '_' x 18;
	$this->{checkvalssl} =~ s/_/int(rand(10))/eg;

	$this->{sid} = $this->_insertSid($this->{checkval}, $this->{checkvalssl}, $this->{data});

    if ($TL->INI->get($this->{group} => 'logging', '0')) {
        $TL->log(__PACKAGE__,
                 "created new session sid [$this->{sid}] on the DB".
                   " [$this->{dbgroup}][$this->{sessiontable}].");
    }
}

sub _insertSid {
    my $this        = shift;
    my $checkval    = shift;
    my $checkvalssl = shift;
    my $data        = shift;

    my $DB   = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    die __PACKAGE__."#__createSid: the type of DB [$this->{dbgroup}] is [$type], which is not supported.".
      " (DB [$this->{dbgroup}] の [$type] は対応していないDBです)\n";
}

sub _deleteSid {
    my $this = shift;
    my $sid  = shift;

    my $DB   = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{DELETE FROM %s WHERE sid = ?},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $sid);

    return $this;
}

sub _createSessionTable {
    my $this = shift;

    my $DB   = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    die __PACKAGE__."#__prepareSessionTable: the type of DB [$this->{dbgroup}] is [$type], which is not supported by the Tripletail::Session.".
      " (DB [$this->{dbgroup}] の [$type] は対応していないDBです)\n";
}

sub _init {
	# TL#startCgiによって呼ばれるクラスメソッド。
	my $class = shift;
	my $groups;
	if(ref($_[0]) eq 'ARRAY') {
		$groups = shift;
	} elsif(!ref($_[0])) {
		$groups = [ @_ ];
	} else {
		my $ref = ref($_[0]);
		die __PACKAGE__."#_init: arg[1] is an unacceptable reference. [$ref] (第1引数が不正なリファレンスです)\n";
	}

	# postRequest時に古いデータを消す。
	$TL->setHook(
		'postRequest',
		_POST_REQUEST_HOOK_PRIORITY,
		sub {
			foreach my $group (@$groups) {
				$_instance{$group}->__reset;
			}
		},
	);
	foreach my $group (@$groups) {

        my $dbgroup = $TL->INI->get((defined $group ? $group : 'Session') => dbgroup => undef);
        my $DB      = $TL->getDB($dbgroup);
        my $type    = $DB->getType;
        my $backend = exists $BACKEND_OF{$type}
                           ? $BACKEND_OF{$type}
                             : die __PACKAGE__."#_init: the type of DB [$dbgroup] is [$type], which is not supported".
                               " (DB [$dbgroup] の [$type] は対応していないDBです)\n";

        eval qq{
            use $backend;
        };
        if ($@) {
            local $SIG{__DIE__} = $@;
            die $@;
        }

        $_instance{$group} = $backend->__new($group);
	}

	undef;
}

sub __new {
	my $class = shift;
	my $group = shift;
	my $this = bless {} => $class;

	$this->{group} = defined $group ? $group : 'Session';

	$this->{mode} = $TL->INI->get($this->{group} => 'mode', 'double');

	my $timeout = $TL->INI->get($this->{group} => 'timeout','30min');
	$this->{timeout_period} = $TL->parsePeriod($timeout);

	my $updateinterval = $TL->INI->get($this->{group} => 'updateinterval','10min');
	$this->{updateinterval_period} = $TL->parsePeriod($updateinterval);

	$this->{setvaluewithrenew} = $TL->INI->get($this->{group} => 'setvaluewithrenew', 1);

	$this->__reset;

	# モードチェック
	if($this->{mode} eq 'https') {
		if(!$this->isHttps) {
			die __PACKAGE__."#__new: the session mode 'https' is not available because we are not in the https connection.".
				" (httpsモードの場合はhttps接続中でのみセッションを利用できます)\n";
		}
	} elsif($this->{mode} eq 'http') {
		# 常に利用可能
	} elsif($this->{mode} eq 'double') {
		# 常に利用可能
	} else {
		die __PACKAGE__."#__new: invalid mode: [$this->{mode}] (不正なモードが指定されました)\n";
	}

	$this->{dbgroup     } = $TL->INI->get($this->{group} => 'dbgroup');
	$this->{dbset       } = $TL->INI->get($this->{group} => 'dbset'  );
	$this->{readdbset   } = $TL->INI->get($this->{group} => readdbset    => $this->{dbset}              );
	$this->{sessiontable} = $TL->INI->get($this->{group} => sessiontable => 'tl_session_'.$this->{group});

    $this->_createSessionTable;

	$this;
}

sub __reset {
	my $this = shift;

	$this->{sid} = undef;
	$this->{data} = undef;
	$this->{checkval} = undef;
	$this->{checkvalssl} = undef;
	$this->{updatetime} = undef; # 新規セッションを作成した場合はundefのまま
}


sub _getInstance {
	# TL#getSessionやTripletail::Filterによって呼ばれるクラスメソッド。
	my $class = shift;
	my $group = shift;

	defined $group or $group = 'Session';

	if($_instance{$group}) {
		$_instance{$group};
	} else {
		die "TL#getSession: the session group [$group] has not been specified at the call of \$TL->startCgi() like ".
			"-Session => '(group)'.".
			" (セッショングループ $group は使用できません。startCgi の -Session で指定する必要があります)\n";
	}
}

sub _getInstanceGroups {
	# Tripletail::Filterなどによって呼ばれるクラスメソッド。
	my $class = shift;

	return keys %_instance;
}

sub _getRawCookie {
    my $this = shift;
    my $opts = { @_ }; # secure => 1 or 0

    my $group  = $opts->{secure}
               ? $TL->INI->get($this->{group} => securecookie => 'SecureCookie')
               : $TL->INI->get($this->{group} => cookie       => 'Cookie'      );
    my $cookie = $TL->getRawCookie($group);
    if ($opts->{secure} && !$cookie->isSecure) {
        die __PACKAGE__."#_getRawCookie: cookie group [$group] is not declared to be secure.".
          " We can't use it for secure part of session.".
            " (セキュアなセッション部分でクッキーグループ $group を使用しようとしましたが、クッキーの secure 指定がされていません)\n";
    }
    elsif (!$opts->{secure} and $cookie->isSecure) {
        die __PACKAGE__."#_getRawCookie: cookie group [$group] is not declared to be secure.".
          " We can't use it for insecure part of session.".
            " (非セキュアなセッション部分でクッキーグループ $group を使用しようとしましたが、クッキーの secure 指定がされています)\n";
    }
    else {
        return $cookie;
    }
}

sub _setSessionDataToCookies {
	# クッキーを使用する場合に，Tripletail::Filter より呼び出される．
	# 必要に応じてセッションデータをCookieにsetする。
	my $this = shift;

	if($this->isHttps) {
		if($this->{mode} eq 'https' || $this->{mode} eq 'double') {
			# https側
			my $cookie = $this->_getRawCookie(secure => 1);

			if(defined($this->{sid})) {
				$this->_updateSession;
				my $s = join('.', $this->{sid}, $this->{checkvalssl});
				$cookie->set('SIDS' . $this->{group} => $s);
			} else {
				$cookie->delete('SIDS' . $this->{group});
			}
		}
		if($this->{mode} eq 'http' || $this->{mode} eq 'double') {
			my $cookie = $this->_getRawCookie(secure => 0);
			if(defined($this->{sid})) {
				my $s = join('.', $this->{sid}, $this->{checkval});
				$cookie->set('SID' . $this->{group} => $s);
			} else {
				$cookie->delete('SID' . $this->{group});
			}
		}
	} else {
		if($this->{mode} eq 'http' || $this->{mode} eq 'double') {
			# http側
			my $cookie = $this->_getRawCookie(secure => 0);

			if(defined($this->{sid})) {
				$this->_updateSession;
				my $s = join('.', $this->{sid}, $this->{checkval});
				$cookie->set('SID' . $this->{group} => $s);
			} else {
				$cookie->delete('SID' . $this->{group});
			}
		} else {
			die __PACKAGE__."#_setSessionDataToCookies: the session mode is `https'.".
				" We can't use it for insecure part of session.".
				" (httpsモードのセッションはhttps接続中でのみ使用できます)\n";
		}
	}

	$this;
}

sub _getSessionDataFromCookies {
	# クッキーを使用する場合に，Tripletail::InputFilter より呼び出される．
	# クッキー中にセッションデータがあれば、それを読む。
	my $this = shift;

	if ($this->{mode} eq 'http' || ((!$this->isHttps) && $this->{mode} eq 'double')) {
		my $cookie = $this->_getRawCookie(secure => 0);

		if(my $s = $cookie->get('SID' . $this->{group})) {
			# http側
			my ($sid, $checkval) = split(/\./, $s);
			$this->_loadSession($sid, $checkval, secure => 0);
		}
	}

	if($this->{mode} eq 'https' || ($this->isHttps and $this->{mode} eq 'double')) {
		my $cookie = $this->_getRawCookie(secure => 1);

		if(my $s = $cookie->get('SIDS' . $this->{group})) {
			# https側
			my ($sid, $checkval) = split(/\./, $s);
			$this->_loadSession($sid, $checkval, secure => 1);
		}
	}

	$this;
}

sub _setSessionDataToForm {
	# フォームを使用する場合に，Tripletail::Filter::MobileHTML より呼び出される．
	# 必要に応じてセッションデータをFormにsetする。
	my $this = shift;
	my $form = shift;
	
	# Form方式はモバイル利用が前提となっている。モバイルでのdoubleモードはエラー
	if($this->{mode} eq 'double') {
		die __PACKAGE__."#_setSessionDataToForm: could not use double mode with MobileHTML filter.".
			" (モバイルではdoubleモードは使えません)\n";
	}
	
	if($this->{mode} eq 'http'){
		if(defined($this->{sid})) {
			$this->_updateSession;
			my $s = join('.', $this->{sid}, $this->{checkval});
			$form->set('SID' . $this->{group} => $s);
		}
	}elsif($this->isHttps) {
		if(defined($this->{sid})) {
			$this->_updateSession;
			my $s = join('.', $this->{sid}, $this->{checkvalssl});
			$form->set('SIDS' . $this->{group} => $s);
		}
	}

	$this;
}

sub _getSessionDataFromForm {
	# フォームを使用する場合に，Tripletail::InputFilter::MobileHTML より呼び出される．
	# フォーム中にセッションデータがあれば、それを読む。
	# NOTE: フォームはモバイル利用が前提となっており、モバイルではdoubleモードは考慮しない
	my $this = shift;
	my $form = shift;

	# Form方式はモバイル利用が前提となっている。モバイルでのdoubleモードはエラー
	if($this->{mode} eq 'double') {
		die __PACKAGE__."#_getSessionDataFromForm: could not use double mode with MobileHTML filter.".
			" (モバイルではdoubleモードは使えません)\n";
	}
	
	if($this->{mode} eq 'http') {
		if(my $s = $form->get('SID' . $this->{group})) {
			# http側
			my ($sid, $checkval) = split(/\./, $s);
			$this->_loadSession($sid, $checkval, secure => 0);
		}
	}elsif($this->{mode} eq 'https') {
		if(my $s = $form->get('SIDS' . $this->{group})) {
			# https側
			my ($sid, $checkval) = split(/\./, $s);
			$this->_loadSession($sid, $checkval, secure => 1);
		}
	}

	$this;
}

sub _loadSession {
    # セッションの存在確認をし，問題がなければデータをセットする．
    my $this     = shift;
    my $sid      = shift;
    my $checkval = shift;
    my %opts     = @_;

    my $DB = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    die __PACKAGE__."#_loadSession: the type of DB [$this->{dbgroup}] is [$type], which is not supported by Tripletail::Session.".
      " (DB [$this->{dbgroup}] の [$type] は対応していないDBです)\n";
}

sub _updateSession {
    my $this = shift;

    my $DB = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    die __PACKAGE__."#_updateSession, the type of DB [$this->{dbgroup}] is [$type], which is not supported by Tripletail::Session.".
      " (DB [$this->{dbgroup}] の [$type] は対応していないDBです)\n";
}


# -----------------------------------------------------------------------------
# ($key, $val, $err) = $sess->_createSessionCheck($issecure).
# $issecure ::= bool.
#
# 現在の実装では, 検証キーとして sid(とcheckval) から固定のハッシュ値が
# 生成される.
# このキーが奪取可能であればそれはセッションキーそのものも同様に
# 奪取可能な自体であるため, セッション内で固定値であることは特に問題にならない.
# 
sub _createSessionCheck
{
	my $this     = shift;
	my $issecure = shift;

	my $sessiongroup = $this->{group};
	my $csrfkey = $TL->INI->get($sessiongroup => 'csrfkey', undef);
	if( !defined($csrfkey) )
	{
		my $err = "csrfkey is not defined for the INI group [$sessiongroup]. (INI [$sessiongroup] で csrfkey を設定してください)\n";
		return (undef, undef, $err);
	}

	my ($key, $sid, $checkval) = $this->getSessionInfo($issecure);

	if( !defined($sid) )
	{
		my $err = "no session ID has been created. You must prepare one before. (セッションがありません。事前にセッションを生成してください)\n";
		return (undef, undef, $err);
	}

	$key = 'C' . $key;
	my $value = hmac_sha1_hex(join('.', $sid, $checkval), $csrfkey);

	($key, $value, undef);
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::Session - セッション

=head1 SYNOPSIS

=head2 PCブラウザ向け

  $TL->startCgi(
      -DB      => 'DB',
      -Session => 'Session',
      -main    => \&main,
  );

  sub main {
      my $session = $TL->getSession('Session');

      my $oldValue = $session->getValue;
      
      $session->setValue(12345);

      ...
  }

=head2 携帯ブラウザ向け

  $TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
  $TL->startCgi(
      -DB      => 'DB',
      -Session => 'Session',
      -main    => \&main,
  );
  
  sub main {
      $TL->setContentFilter(
          'Tripletail::Filter::MobileHTML',
          charset => 'Shift_JIS',
      );
      my $session = $TL->getSession('Session');

      my $oldValue = $session->getValue;
      
      $session->setValue(12345);

      ...
  }

=head1 DESCRIPTION

64bit符号無し整数値の管理機能を持ったセッション管理クラス。

セッションは64bit整数から負の数を除いた範囲（0..9223372036854775807）以外の
データを取り扱えない為、その他のデータを管理したい場合は、
セッションキーを用い別途管理する必要がある。 

セッションの管理は L<DB|Tripletail::DB> を利用して行われる。

また、保存に利用するテーブルは自動的に作成される。
デフォルトでは C<tl_session_Session> という名前になる。
(Ini 項目 L</sessiontable> 参照)


プログラム本体とDB接続を共有するため、以下の点に注意しなければならない。

=over 4

=item *

セッションの操作は、トランザクション中及びテーブルロック中には行わない。

=item *

コンテンツの出力操作は、トランザクション中及びテーブルロック中には行わない。

=back

セッションキーは、 L<出力フィルタ|Tripletail/"出力フィルタ"> に L<Tripletail::Filter::HTML>
を使用している場合は L<クッキー|Tripletail::Cookie> に、 L<Tripletail::Filter::MobileHTML>
の場合は L<クエリ|Tripletail::Form> に、それぞれ挿入される。

また、 L<入力フィルタ|Tripletail/"入力フィルタ"> に L<Tripletail::InputFilter::HTML>
を使用している場合は L<クッキー|Tripletail::Cookie> から、L<Tripletail::InputFilter::MobileHTML>
の場合は L<クエリ|Tripletail::Form> から、それぞれ読み取られる。

出力フィルタに L<Tripletail::Filter::HTML> を利用した場合は、
入力フィルタに L<Tripletail::InputFilter::HTML> を使用する必要がある。

同様に、出力フィルタに L<Tripletail::Filter::MobileHTML> を利用した場合は、
入力フィルタに L<Tripletail::InputFilter::MobileHTML> を使用する必要がある。

出力フィルタに L<Tripletail::Filter::MobileHTML> を利用する場合は
フォームの利用の仕方に注意が必要であるため、
L<Tripletail::Filter::MobileHTML> ドキュメントに書かれている
利用方法を別途確認すること。

=head2 METHODS

=over 4

=item C<< $TL->getSession >>

  $session = $TL->getSession($group)

Tripletail::Session オブジェクトを取得。
引数には L<ini|Tripletail::Ini> で設定したグループ名を渡す。省略可能。

このメソッドは、 L<Tripletail#startCgi|Tripletail/"startCgi">
の呼び出し時に C<< -Session => '(Iniグループ名)' >> で指定されたグループのセッションが有効化
されていなければ C<die> する。

引数省略時は 'Session' グループが使用される。

=item C<< isHttps >>

  $session->isHttps

現在のリクエストがhttpsなら1を、そうでなければundefを返す。

  if ($session->isHttps) {
      ...
  }

=item C<< get >>

  $sid = $session->get

ユニークなセッションキーを取得する。

セッションキーは64bit整数値の負の数を除いた範囲となる。

Perlでは通常32bit整数値までしか扱えないため、セッションキーを数値として扱ってはならない。

セッションが存在しなければ、新規に発行する。

セッションの発行は常に行え、double モード時の非SSL側からの get メソッド呼び出しでもセッションは設定される。
ただし、SSL側からアクセスした際にセッションが無効になるため、その時にセッションIDは再作成される。

このメソッドの呼び出しは、コンテンツデータを返す前に行わなければならない。

=item C<< renew >>

  $sid = $session->renew

新しくユニークなセッションキーを発行し、取得する。

以前のセッションキーが存在した場合、そのセッションキーは無効となる。
また、以前のセッションに保存されていた値も破棄される。

このメソッドの呼び出しは、コンテンツデータを返す前に行わなければならない。

=item C<< discard >>

  $session->discard

現在のセッションキーを無効にする。
また、セッションに保存されていた値も破棄される。

このメソッドの呼び出しは、コンテンツデータを返す前に行わなければならない。

=item C<< setValue >>

  $session->setValue($value)

セッションに値を設定する。

設定できる値は '64bit符号無し整数' のみ（※PostgreSQL利用時は64bit整数値のみ）。
その他のデータを管理したい場合は、セッションキーを用いて別途実装する必要がある。

doubleモードの場合は、SSL起動時の場合に限り、両方のセッションに書き込まれる。
doubleモードで非SSL側からこのメソッドを使ってセッションを書換えようとした場合、
httpsモードで非SSL側から書き換えようとした場合は C<die> する。

このメソッドの呼び出しは、コンテンツデータを返す前に行わなければならない。

=item C<< getValue >>

  $value = $session->getValue

セッションから値を取得する。

セッションが存在しない場合は undef を返す。

=item C<< getSessionInfo >>

  ($name, $sid, $checkval) = $session->getSessionInfo

セッション情報を取得する。

クッキーやフォームにセッションを保存する際の名称、セッションキー、チェック値を返す。
チェック値は、現在のリクエストが https/http によって使用されているものが返される。
そのため、double モードの場合、現在のリクエスト状態に応じてチェック値が異なる。

セッションが存在しない場合は $sid、$checkval には undef が返る。

=back


=head2 古いセッションデータの削除

TripletaiL は、古いセッションデータを削除することはしません。

パフォーマンスを維持するため、古いセッションデータを定期的に削除するバッチを作成し、定期的に
実行するようにして下さい。

削除は以下のようなクエリで行えます。

 DELETE FROM tablename WHERE updatetime < now() - INTERVAL 7 DAY LIMIT 10000

セッションの保存期間にあわせて、WHERE条件を変更して下さい。

また、セッションテーブルがMyISAM形式の場合は、LIMIT句を付けて一度に削除する
レコード件数を制限し、長時間ロックがかからないようにすることを推奨します。

DELETE結果の件数が0件になるまで、ループして処理して下さい。

セッションテーブルがInnoDB形式の場合も、トランザクションが大きくなりすぎないよう、
LIMIT句を利用することを推奨します。

=head3 TripletaiL 0.29 以前のセッションテーブルの注意

TripletaiL 0.29 以前では、セッションテーブルを作成する際に、
updatetime カラムにインデックスを張っていませんでした。

レコードの件数が多い場合、古いデータの削除に時間がかかることがあります。
その場合は、updatetime カラムにインデックスを張るようにして下さい。

0.30以降では、セッションテーブル作成時にインデックスを張るように動作が変更されています。

 ALTER TABLE tablename ADD INDEX (updatetime);
 CREATE INDEX tablename_updtime_idx ON tablename (updatetime);


=head2 Ini パラメータ

=over 4

=item mode

  mode = double

設定可能な値は、'http'、 'https'、 'double'のいずれか。省略可能。

デフォルトはdouble。

=over 8

=item httpモード

SSLでの保護がないセッションを利用する。http/httpsの両方で使用できるが、セッションキーはhttp側から漏洩する可能性があるため、https領域からアクセスした場合も、十分な安全性は確保できないことに注意する必要がある。

=item httpsモード

SSLでの保護があるセッションを利用する。セッションキーはhttp側からの漏洩を防ぐため、http通信上には出力されない。https側でのみセッションへのアクセスが可能。

=item doubleモード

http側とhttps側で二重にセッションを張る。
https側からのみセッションへの書き込み・破棄が行え、その際にhttp側のセッション情報も同時に書き換えられる。
http側からはhttps側からセットされたセッション情報の参照のみが出来る。

http側はセッションキー漏洩の危険性があり、十分な安全性は確保できないが、https側は十分な安全性が確保できる。http側からセッションキーが漏洩した場合でも、https領域でのアクセスは安全である。

                http領域読込    http領域書込    https領域読込   http領域書込
  httpモード    ○              ○              ○              ○
  httpsモード   die             die             ○              ○
  doubleモード  ○              die             ○              ○

=back

=item cookie

  cookie = Cookie

http領域で使用するクッキーのグループ名を指定する。省略可能。

デフォルトは'Cookie'。

=item securecookie

https 領域で使用するクッキーのグループ名を指定する。省略可能。
secureフラグが付いていなければエラーとなる。

デフォルトは'SecureCookie'．

=item timeout

  timeout = 30 min

指定の時間経過したセッションは無効とする。L<度量衡|Tripletail/"度量衡"> 参照。省略可能。
最短で timeout - updateinterval の時間でタイムアウトする可能性がある。

デフォルトは30min。

=item updateinterval

  updateinterval = 10 min

最終更新時刻から指定時間以上経過していたら、DBの更新時刻を更新する。L<度量衡|Tripletail/"度量衡"> 参照。省略可能。
最短で timeout - updateinterval の時間でタイムアウトする可能性がある。

デフォルトは10min。

=item setvaluewithrenew

  setvaluewithrenew = 1

setValueした際に自動的にrenewを行うか否か。
0の場合、行わない。
1の場合、行う。

デフォルトは1。

=item dbgroup

  dbgroup = DB

使用するDBのグループ名。
L<ini|Tripletail::Ini> で設定したグループ名を渡す。
L<Tripletail#startCgi|Tripletail/"startCgi"> で有効化しなければならない。

=item dbset

  dbset = W_Trans

使用する書き込み用DBセット名。
L<Tripletail#startCgi|Tripletail/"startCgi"> で有効化しなければならない。
L<ini|Tripletail::Ini> で設定したグループ名を渡す。

=item readdbset

  readdbset = R_Trans

使用する読み込み用DBセット名。
L<Tripletail#startCgi|Tripletail/"startCgi"> で有効化しなければならない。
L<ini|Tripletail::Ini> で設定したグループ名を渡す。

省略された場合は dbset と同じものが使用される。

=item sessiontable

  sessiontable = tl_session

セッションで使用するテーブル名。
デフォルトは tl_session_グループ名 が使用される。

=item mysqlsessiontabletype

  mysqlsessiontabletype = InnoDB

MySQLの場合、セッションで使用するテーブルの種類を何にするかを指定する。
デフォルトは指定無し。

セッションの管理情報が重要である場合、例えばアフィリエイトの追跡に
利用していて、セッションが意図せず途切れるとユーザに金銭的被害が
生じるような場合は、InnoDB を利用することを推奨します。

それ以外の場合は、MyISAM を利用することを推奨します。
TripletaiL のセッションテーブルは Fixed 型となるため、
非常に高速にアクセスできます。

=item csrfkey

  csrfkey = JLapCbI4XW7G8oEi

addSessionCheck及びhaveSessionCheckで使用するキー。
サイト毎に値を変更する必要性がある。

=item logging

  logging = 1

セッション管理のログを出力するかを指定する。
1 を指定するとセッション管理情報をログに出力する。0 なら出力しない。
デフォルトは 0。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Cookie>

=item L<Tripletail::DB>

=item L<Tripletail::Filter::HTML>

=item L<Tripletail::Filter::MobileHTML>

=item L<Tripletail::InputFilter::HTML>

=item L<Tripletail::InputFilter::MobileHTML>

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
