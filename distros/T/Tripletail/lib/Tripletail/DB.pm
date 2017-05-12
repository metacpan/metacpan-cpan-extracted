# -----------------------------------------------------------------------------
# Tripletail::DB - DBIのラッパ
# -----------------------------------------------------------------------------
package Tripletail::DB;
use strict;
use warnings;
use Tripletail;
use Tripletail::DB::Dbh;
use Tripletail::DB::Sth;
use Scalar::Lazy;
use Hash::Util qw(lock_hash);
use Time::HiRes;
use DBI qw(:sql_types);

sub _INIT_REQUEST_HOOK_PRIORITY() { -1_000_000 } # 順序は問わない
sub _POST_REQUEST_HOOK_PRIORITY() { -1_000_000 } # セッションフックの後
sub _TERM_HOOK_PRIORITY()         { -1_000_000 } # セッションフックの後

my %INSTANCES; # グループ名 => インスタンス

sub _TX_STATE_NONE()      { 0 }
sub _TX_STATE_ACTIVE()    { 1 }
sub _TX_STATE_CLOSEWAIT() { 2 }
our $_tx_state = _TX_STATE_NONE; # dynamically scoped

my %BACKEND_OF = (
    mysql     => 'Tripletail::DB::Backend::MySQL',
    pgsql     => 'Tripletail::DB::Backend::PgSQL',
    oracle    => 'Tripletail::DB::Backend::Oracle',
    interbase => 'Tripletail::DB::Backend::Interbase',
    sqlite    => 'Tripletail::DB::Backend::SQLite',
    mssql     => 'Tripletail::DB::Backend::MSSQL',
   );
lock_hash(%BACKEND_OF);

1;

sub _getInstance {
	my $class = shift;
	my $group = shift;

	if(!defined($group)) {
		$group = 'DB';
	} elsif(ref($group)) {
		die "TL#getDB: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}

	my $obj = $INSTANCES{$group};
	if(!$obj) {
		die "TL#getDB: DB group [$group] was not passed to the startCgi() / trapError(). (startCgi/trapErrorのDBに指定されていないDBグループ[${group}]が指定されました)\n";
	}

	$obj;
}

sub _reconnectSilentlyAll {
    # fork された後、子プロセス側で呼ばれる。現在 %INSTANCES に保存されている
    # DBI-dbh は全て親と共有されているので、それら全ての InactiveDestroy フラグを
    # 立ててから接続し直さなければならない。
    foreach my $db (values %INSTANCES) {
        $db->_reconnectSilently;
    }

    return;
}

sub _reconnectSilently {
    my $this = shift;

    # 全ての DB コネクションの InactiveDestroy フラグを立ててから再接続する。
    foreach my $dbh (values %{$this->{dbname}}) {
        $dbh->getDbh->{InactiveDestroy} = 1;
        $dbh->connect;
    }

    $this;
}


sub connect {
	my $this = shift;

	# 全てのDBコネクションの接続を確立する．
	foreach my $dbh (values %{$this->{dbname}}) {
		if(!$dbh->ping) {
			$dbh->connect;
		}
	}

	$this;
}

sub disconnect {
	my $this = shift;

	foreach my $dbh (values %{$this->{dbname}}) {
		$dbh->disconnect;
	}

	$this;
}

sub tx {
    my $this    = shift;
    my $setname = !ref($_[0]) && shift;
    my $sub     = shift;

    if ($_tx_state == _TX_STATE_CLOSEWAIT) {
        $this->_closewait_broken();
    }

    local $Tripletail::Error::LAST_DB_ERROR
      = lazy { $this->getDbh($setname)->_errinfo };

    my @ret;
    while (1) {
        $this->begin($setname);
        local $_tx_state = _TX_STATE_ACTIVE;

        if (wantarray) {
            @ret = eval { $sub->() };
        }
        else {
            $ret[0] = eval { scalar $sub->() };
        }
        if (my $err = $@) {
            my $set = $this->_getDbSetName($setname);
            my $dbh = $this->{dbh}{$set};
            if ($this->{autoretry} and
                  $dbh->_last_error_info->{errkey} eq 'DEADLOCK_DETECTED') {
                if ($this->{trans_dbh}) {
                    $this->rollback();
                }
                $TL->log(
                    __PACKAGE__,
                    "Detected a deadlock. Restarting the transaction...");
                redo;
            }
            else {
                if ($this->{trans_dbh}) {
                    $this->rollback();
                }
                local $SIG{__DIE__} = 'DEFAULT';
                die $err;
            }
        }
        else {
            if ($this->{trans_dbh}) {
                $this->commit();
            }
            last;
        }
    }

    if (wantarray) {
        return @ret;
    }
    else {
        return $ret[0];
    }
}

sub _closewait_broken
{
	my $this = shift;
	my $where = shift;
	if( !$where )
	{
		$where = (caller(1))[3];
		$where =~ s/.*:://;
	}
	die __PACKAGE__."#$where: you can't do anything related to DB after doing rollback or commit in tx(). (txの中でrollback/commitした後はSQLを実行できません)\n";
}
sub inTx
{
	my $this = shift;
	my $set  = shift;
	$this->_requireTx($set, 'inTx');
}
sub _requireTx
{
	my $this    = shift;
	my $setname = shift;
	my $where   = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken($where);
	}
	if( my $trans = $this->{trans_dbh} )
	{
		my $set = $this->_getDbSetName($setname);

		my $trans_set = $trans->getSetName;
		if($trans_set eq $set)
		{
			# same transaction.
			return 1;
		}
		# another transaction running, always die.
		die __PACKAGE__."#$where: attempted to begin a".
			" new transaction on DB Set [$set] but".
			" another DB Set [$trans_set] were already in transaction.".
			" Commit or rollback it before beginning another one.".
			" (DB Set [$trans_set] でトランザクションを実行中に DB Set [$set] でトランザクションを開始しようとしました。".
			"別の DB Set でトランザクションを開始する前にcommit/rollbackする必要があります)\n";
	}else
	{
		# no transaction.
		return 0;
	}
}

sub begin {
	my $this = shift;
	my $setname = shift;

	my $set = $this->_getDbSetName($setname);

	$this->_requireTx($setname, 'begin');

	my $begintime = [Time::HiRes::gettimeofday()];

	my $dbh = $this->{dbh}{$set};
	$dbh->begin;

	my $elapsed = Time::HiRes::tv_interval($begintime);

	my $sql = $this->__nameQuery('BEGIN', $dbh);

    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => -1,
               query   => $sql,
               params  => [],
               elapsed => $elapsed }
        });

	$this->{trans_dbh} = $dbh;
	$this;
}

sub rollback {
	my $this = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	my $dbh = $this->{trans_dbh};
	if(!defined($dbh)) {
		die __PACKAGE__."#rollback: not in transaction. (トランザクションの実行中ではありません)\n";
	}

	my $begintime = [Time::HiRes::gettimeofday()];

	$dbh->rollback;
	if ($_tx_state == _TX_STATE_ACTIVE) {
		$_tx_state = _TX_STATE_CLOSEWAIT;
	}

	my $elapsed = Time::HiRes::tv_interval($begintime);

	my $sql = $this->__nameQuery('ROLLBACK', $dbh);

    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => -1,
               query   => $sql,
               params  => [],
               elapsed => $elapsed }
        });

	$this->{trans_dbh} = undef;
	$this;
}

sub commit {
	my $this = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	my $dbh = $this->{trans_dbh};
	if (!defined($dbh)) {
		die __PACKAGE__."#commit: not in transaction. (トランザクションの実行中ではありません)\n";
	}

	my $begintime = [Time::HiRes::gettimeofday()];

	$dbh->commit;
	if ($_tx_state == _TX_STATE_ACTIVE) {
		$_tx_state = _TX_STATE_CLOSEWAIT;
	}

	my $elapsed = Time::HiRes::tv_interval($begintime);

	my $sql = $this->__nameQuery('COMMIT', $dbh);

    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => -1,
               query   => $sql,
               params  => [],
               elapsed => $elapsed }
        });

	$this->{trans_dbh} = undef;
	$this;
}

sub setDefaultSet {
	my $this = shift;
	my $setname = shift;

	if(defined($setname)) {
		$this->{default_set} = $this->_getDbSetName($setname);
	} else {
		$this->{default_set} = undef;
	}

	$this;
}

sub execute {
	my $this = shift;
	my $dbset = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	if(ref($dbset)) {
		$dbset = $$dbset;
	} else {
		unshift(@_, $dbset);
		$dbset = undef;
	}
	my $sql = shift;
	my $sql_backup = $sql; # デバッグ用

	if(!defined($sql)) {
		die __PACKAGE__."#execute: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($sql)) {
		die __PACKAGE__."#execute: arg[1] is a reference. (第1引数がリファレンスです)\n";
	} elsif($sql =~ m/^\s*(LOCK|UNLOCK|BEGIN|ROLLBACK|COMMIT)/i) {
		# これらのSQL文をexecuteすると整合性が失われる。
		die __PACKAGE__."#execute: attempted to execute [$1] statement directly.".
			" Use special methods not to ruin the consistency of Tripletail::DB.".
			" ($1はTripletail::DBの状態管理に影響を与えるためexecuteで実行できません。専用のメソッドを利用してください)\n";
	}

	my @params;
	if($sql =~ m/\?\?/) {
		# パラメータの中からARRAY Refのものを全て抜き出し、 ?? を ?, ?, ... に置換
		foreach my $param (@_) {
			if(!ref($param)) {
				push @params, $param;
			} elsif(ref($param) eq 'ARRAY') {
				if(@$param == 0) {
					# 0要素の配列があってはならない。
					die __PACKAGE__."#execute: some arguments are an empty array. (空の配列へのリファレンスが渡されました)\n";
				}

				my $n_params = @$param;

				if(ref($param->[-1]) eq 'SCALAR') {
					# 最後の要素がSCALAR Refなら、それは全体の型指定。

					my $type = $param->[-1];
					$n_params--;

					for(my $i = 0; $i < @$param - 1; $i++) {
						if(ref($param->[$i]) eq 'ARRAY') {
							# これは個別に型が指定されているので、デフォルトの型を適用しない。
							push @params, $param->[$i];
						} else {
							push @params, [$param->[$i], $type];
						}
					}
				} else {
					push @params, @$param;
				}

				unless($sql =~ s{\?\?}{
					join(', ', ('?') x $n_params);
				}e) {
					die __PACKAGE__."#execute: the number of `??' is fewer than the number of given parameters. (??の数が不足しています)\n";
				}
			} else {
				die __PACKAGE__."#execute: arg[$param] is not a scalar nor ARRAY Ref. (arg[$param]はスカラでも配列へのリファレンスでもありません)\n";
			}
		}

		if($sql =~ m/\?\?/) {
			die __PACKAGE__."#execute: the number of given parameters is fewer than the number of `??'. (??の数に対して引数の数が不足しています)\n";
		}
	} else {
		@params = @_;

		# この中にARRAY Refが入っていてはならない。
		if(grep {ref eq 'ARRAY'} @params) {
			die __PACKAGE__."#execute: use `??' instead of `?' if you want to use ARRAY Ref as a bind parameter.".
				" (配列へのリファレンスは ?? に対してのみ使用できます)\n";
		}
	}
	
	# executeを行うDBセットを探す
	my $dbh = undef;
	if(defined($dbset)) {
		#DBセットが明示的に指定された
		$dbh = $this->{dbh}{$dbset};
		if(!$dbh) {
			die __PACKAGE__."#execute: DB set [$dbset] is unavailable. (DB Set [$dbset] の指定が不正です)\n";
		}
	} else {
		$dbh = $this->{trans_dbh};
		$dbh = $this->{locked_dbh} if(!$dbh);
		$dbh = $this->{dbh}{$this->_getDbSetName} if(!$dbh);
	}
	
	if( $dbh->{bindconvert} )
	{
		my $sub = $dbh->{bindconvert};
		$dbh->$sub(\$sql, \@params);
	}

	my $sth = Tripletail::DB::Sth->new(
		$this,
		$dbh,
		$dbh->getDbh->prepare($sql)
	);
	if( $dbh->{fetchconvert} )
	{
		my $sub = $dbh->{fetchconvert};
		$dbh->$sub($sth, new => [\$sql, \@params]);
	}

	# 全てのパラメータをbind_paramする。
	for(my $i = 0; $i < @params; $i++) {
		my $p = $params[$i];
		my $argno = $i + 2;

		if(!ref($p)) {
			$sth->{sth}->bind_param($i + 1, $p);
		} elsif(ref($p) eq 'ARRAY') {
			if(@$p != 2 || ref($p->[1]) ne 'SCALAR') {
				die __PACKAGE__."#execute: arg[$argno]: attempted to bind an invalid array: [".join(', ', @$p)."]".
				" (第${argno}引数に不正な形式の配列が渡されました)\n";
			}

			my $type = ${$p->[1]};
			my $typeconst = $this->{types_symtable}{$type};
			if(!$typeconst) {
				die __PACKAGE__."#execute: arg[$argno] is an invalid sql type: [$type] (第${argno}引数のSQL型指定が不正です)\n";
			}
			$p->[1] = *{$typeconst}{CODE}->();

			$sth->{sth}->bind_param($i + 1, @$p);
		} else {
			die __PACKAGE__."#execute: arg[$argno] is an unacceptable reference. [$p] (第${argno}引数に不正なリファレンスが渡されました)\n";
		}
	}

	$sql = $this->__nameQuery($sql, $dbh);
	$sql_backup = $this->__nameQuery($sql_backup, $dbh);

	my $begintime = [Time::HiRes::gettimeofday()];
	my $log_params = \@_;

    while (1) {
        $TL->eval(sub{ $sth->{ret} = $sth->{sth}->execute });
        if (my $err = $@) {
            if ($dbh->_last_error_info->{errkey} eq 'DEADLOCK_DETECTED') {
                if (not $this->{trans_dbh}) {
                    $TL->log(
                        __PACKAGE__,
                        "Detected a deadlock. Restarting the transaction...");
                    redo;
                }
            }

            my $elapsed = Time::HiRes::tv_interval($begintime);
            $TL->getDebug->_dbLog(
                lazy {
                    +{ group   => $this->{group},
                       set     => $dbh->getSetName,
                       db      => $dbh->getGroup,
                       id      => $sth->{id},
                       query   => $sql_backup . " /* ERROR: $err */",
                       params  => $log_params,
                       elapsed => $elapsed,
                       names   => $TL->eval(sub{ $sth->nameArray }) || undef,
                       error   => 1 }
                });

            die $err;
        }
        else {
            last;
        }
    }

    my $elapsed = Time::HiRes::tv_interval($begintime);
    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => $sth->{id},
               query   => $sql_backup,
               params  => $log_params,
               elapsed => $elapsed,
               names   => $TL->eval(sub{ $sth->nameArray }) || undef }
        });

    $sth;
}

sub upsert {
    my $this  = shift;

    if ($_tx_state == _TX_STATE_CLOSEWAIT) {
        $this->_closewait_broken();
    }

    my ($dbset, $schema, $table, $keys, $values) = do {
        if (@_ == 5) {
            @_;
        }
        elsif (@_ == 4) {
            if (ref $_[0]) {
                # ($dbset, ...)
                if (ref $_[2]) {
                    # ($dbset, $table, $keys, $values)
                    ($_[0], undef, @_[1, 2, 3]);
                }
                else {
                    # ($dbset, $schema, $table, $keys)
                    (@_, {});
                }
            }
            else {
                # ($schema, $table, $keys, $values)
                (undef, @_);
            }
        }
        elsif (@_ == 3) {
            if (ref $_[0]) {
                # ($dbset, $table, $keys)
                ($_[0], undef, @_[1, 2], {});
            }
            else {
                if (ref $_[1]) {
                    # ($table, $keys, $values)
                    (undef, undef, @_);
                }
                else {
                    # ($schema, $table, $keys)
                    (undef, @_, {});
                }
            }
        }
        elsif (@_ == 2) {
            # ($table, $keys)
            (undef, undef, @_, {});
        }
        else {
            die __PACKAGE__."#upsert, illegal number of arguments. (引数の数が不正です)\n";
        }
    };

    my $dbh = do {
        if (defined $dbset) {
            # DBセットが明示的に指定された
            if (ref($dbset) ne 'SCALAR') {
                die __PACKAGE__."#upsert, arg[dbset] is not a SCALAR ref (arg[dbset] がスカラーリファレンスでありません)\n";
            }

            my $dbh = $this->{dbh}{$$dbset};
            if (!defined $dbh) {
                die __PACKAGE__."#upsert, DB set [$$dbset] is unavailable. (DB Set [$$dbset] の指定が不正です)\n";
            }

            $dbh;
        }
        else {
            $this->{trans_dbh}      ? $this->{trans_dbh}
              : $this->{locked_dbh} ? $this->{locked_dbh}
              : $this->{dbh}{$this->_getDbSetName};
        }
    };

    if (!defined $table) {
        die __PACKAGE__."#upsert, arg[table] is undefined (arg[table] が未定義です)\n";
    }
    elsif (defined $schema && ref $schema) {
        die __PACKAGE__."#upsert, arg[schema] is a ref (arg[schema] がリファレンスです)\n";
    }
    elsif (ref $table) {
        die __PACKAGE__."#upsert, arg[table] is a ref (arg[table] がリファレンスです)\n";
    }
    elsif (ref($keys) ne 'HASH') {
        die __PACKAGE__."#upsert, arg[keys] is not an HASH ref (arg[keys] が HASH リファレンスでありません)\n";
    }
    elsif (keys %$keys == 0) {
        die __PACKAGE__."#upsert, arg[keys] is an empty HASH ref (arg[keys] が空の HASH リファレンスです)\n";
    }
    elsif (ref($values) ne 'HASH') {
        die __PACKAGE__."#upsert, arg[values] is not an HASH ref (arg[values] が HASH リファレンスでありません)\n";
    }

    my $sql = $this->__nameQuery(
                  $dbh->_mk_upsert_query($schema, $table, $keys, $values), $dbh);

    my $begintime = [Time::HiRes::gettimeofday()];
    while (1) {
        $TL->eval(sub{ $dbh->{dbh}->do($sql) });
        if (my $err = $@) {
            if ($dbh->_last_error_info->{errkey} eq 'DEADLOCK_DETECTED') {
                if (not $this->{trans_dbh}) {
                    $TL->log(
                        __PACKAGE__,
                        "Detected a deadlock. Restarting the transaction...");
                    redo;
                }
            }

            my $elapsed = Time::HiRes::tv_interval($begintime);
            $TL->getDebug->_dbLog(
                lazy {
                    +{ group   => $this->{group},
                       set     => $dbh->getSetName,
                       db      => $dbh->getGroup,
                       id      => -1,
                       query   => $sql,
                       params  => [],
                       elapsed => $elapsed,
                       error   => 1 }
                });

            die $err;
        }
        else {
            last;
        }
    }

    my $elapsed = Time::HiRes::tv_interval($begintime);
    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => -1,
               query   => $sql,
               params  => [],
               elapsed => $elapsed }
        });

    return $this;
}

sub selectAllHash {
	my $this = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	my $sth = $this->execute(@_);
	my $result = [];
	while(my $data = $sth->fetchHash) {
		push @$result, { %$data };
	}
	$result;
}

sub selectAllArray {
	my $this = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	my $sth = $this->execute(@_);
	my $result = [];
	while (my $data = $sth->fetchArray) {
		push @$result, [ @$data ];
	}
	$result;
}

sub selectRowHash {
	my $this = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	my $sth = $this->execute(@_);
	my $data = $sth->fetchHash();
	$data = $data ? {%$data} : undef;
	$sth->finish();

	$data;
}

sub selectRowArray {
	my $this = shift;

	if ($_tx_state == _TX_STATE_CLOSEWAIT) {
		$this->_closewait_broken();
	}

	my $sth = $this->execute(@_);
	my $data = $sth->fetchArray();
	$data = $data ? [@$data] : undef;
	$sth->finish();

	$data;
}

sub findTables {
    my $this = shift;
    my $args = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };

    my $set = $this->_getDbSetName($args->{set});
    my $dbh = $this->{dbh}{$set};

    return Tripletail::DB::Sth->new(
               $this,
               $dbh,
               $dbh->getDbh->table_info(
                   undef, $args->{schema}, $args->{table}, 'TABLE'));
}

sub getTableColumns {
    my $this = shift;

    my ($dbset, $schema, $table) = do {
        if (@_ == 3) {
            @_;
        }
        elsif (@_ == 2) {
            if (ref $_[0]) {
                # ($dbset, table)
                ($_[0], undef, $_[1]);
            }
            else {
                # ($schema, $table)
                (undef, @_);
            }
        }
        elsif (@_ == 1) {
            # ($table)
            (undef, undef, @_);
        }
        else {
            die __PACKAGE__."#getTableColumns, illegal number of arguments. (引数の数が不正です)\n";
        }
    };

    my $escaped_schema
      = defined $schema ? $this->escapeLike($schema, $$dbset)
      :                   undef
      ;
    my $escaped_table
      = defined $table  ? $this->escapeLike($table,  $$dbset)
      :                   undef
      ;
    my $set = $this->_getDbSetName($$dbset);
    my $dbh = $this->{dbh}{$set};
    my $sth = $dbh->getDbh->column_info(
                  undef, $escaped_schema, $escaped_table, undef);

    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row;
    }

    if (@rows) {
        return \@rows;
    }
    else {
        return;
    }
}

sub lock {
    my $this = shift;
    my $opts = { @_ };

    my @tables;         # [name, alias, 'WRITE' or 'READ']
    foreach my $type (qw(read write)) {
        if (defined(my $table = $opts->{$type})) {
            if (!ref $table) {
                push @tables, [$table, undef, uc $type];
            }
            elsif (ref($table) eq 'ARRAY') {
                push @tables,
                  map {
                      if (!defined) {
                          die __PACKAGE__."#lock: $type => [...] contains an undef. (${type}にundefが含まれています)\n";
                      }
                      elsif (ref($_) eq 'HASH' && scalar(keys %$_) == 1) {
                          [(keys %$_)[0], (values %$_)[0], uc $type];
                      }
                      elsif (ref) {
                          die __PACKAGE__."#lock: $type => [...] contains a reference. [$_] (${type}にリファレンスが含まれています)\n";
                      }
                      else {
                          [$_, undef, uc $type];
                      }
                  } @$table;
            }
            else {
                die __PACKAGE__."#lock: arg[$type] is an unacceptable reference. [$table] (arg[$type]は不正なリファレンスです)\n";
            }
        }
    };

    if(!@tables) {
        die __PACKAGE__."#lock: no tables are being locked. Specify at least one table. (テーブルが1つも指定されていません)\n";
    }

    my $set = $this->_getDbSetName($opts->{set});

    if (my $locked = $this->{locked_dbh}) {
        my $locked_set = $locked->getSetName;
        if ($locked_set eq $set) {
            die __PACKAGE__."#lock: you are already locking some tables.".
            " (既に他のテーブルをロック中です)\n";
        }
        else {
            die __PACKAGE__."#lock: attempted to lock the DB Set [$set] but ".
            "another DB Set [$locked_set] were locked. Unlock old one before locking new one.".
            " (他の DB Set [$locked_set] でロック中なので DB Set [$set] でロックをすることができません)\n";
        }
    }

    my $dbh = $this->{dbh}{$set};
    my $sql = $this->__nameQuery(
                  $dbh->_mk_locking_query(\@tables), $dbh);

    my $begintime = [Time::HiRes::gettimeofday()];

    $dbh->{dbh}->do($sql);
    $dbh->{locked} = 1;

    my $elapsed = Time::HiRes::tv_interval($begintime);
    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => -1,
               query   => $sql,
               params  => [],
               elapsed => $elapsed }
        });

    $this->{locked_dbh} = $dbh;
    $this;
}

sub unlock {
    my $this = shift;

    if ($_tx_state == _TX_STATE_CLOSEWAIT) {
        $this->_closewait_broken();
    }

    my $dbh = $this->{locked_dbh};
    if (!defined($dbh)) {
        die __PACKAGE__."#unlock: no tables are locked. (ロックされているテーブルはありません)\n";
    }

    my $sql = $this->__nameQuery(
                  $dbh->_mk_unlocking_query, $dbh);

    my $begintime = [Time::HiRes::gettimeofday()];

    $dbh->{dbh}->do($sql);
    $dbh->{locked} = undef;

    my $elapsed = Time::HiRes::tv_interval($begintime);
    $TL->getDebug->_dbLog(
        lazy {
            +{ group   => $this->{group},
               set     => $dbh->getSetName,
               db      => $dbh->getGroup,
               id      => -1,
               query   => $sql,
               params  => [],
               elapsed => $elapsed }
        });

    $this->{locked_dbh} = undef;
    $this;
}

sub setBufferSize {
	my $this = shift;
	my $kib = shift;

	if(ref($kib)) {
		die __PACKAGE__."#setBufferSize: arg[1] is a reference. (第1引数がリファレンスです)\n";
	}

	$this->{bufsize} = defined $kib ? $kib * 1024 : undef;
	$this;
}

sub getLastInsertId
{
	my $this = shift;
	my $dbh;
	if( @_ && ref($_[0]) )
	{
		my $dbset_ref = shift;
		$dbh ||= $this->{dbh}{$$dbset_ref};
		$dbh or warn Dumper([keys %{$this->{dbh}}]); use Data::Dumper;
		$dbh or die "no such dbset: $$dbset_ref";
	}else
	{
		$dbh ||= $this->{trans_dbh};
		$dbh ||= $this->{locked_dbh};
		$dbh ||= $this->{dbh}{$this->_getDbSetName};
	}
	$dbh->getLastInsertId(@_);
}

sub quote {
    my $this    = shift;
    my $str     = shift;
    my $setname = shift;

    my $set = $this->_getDbSetName($setname);
    return $this->{dbh}{$set}->quote($str);
}

sub symquote {
    my $this    = shift;
    my $str     = shift;
    my $setname = shift;

    my $set = $this->_getDbSetName($setname);
    return $this->{dbh}{$set}->symquote($str);
}

sub escapeLike {
    my $this    = shift;
    my $str     = shift;
    my $setname = shift;

    my $set = $this->_getDbSetName($setname);
    return $this->{dbh}{$set}->escapeLike($str);
}

sub getType {
    my $this = shift;

    $this->{type};
}

sub getDbh {
	my $this = shift;
	my $setname = shift;

	my $set = $this->_getDbSetName($setname);
	$this->{dbh}{$set}->getDbh;
}

sub _getDbSetName {
	my $this = shift;
	my $setname = shift;

	if(ref($setname)) {
		die __PACKAGE__."#_getDbSetName: arg[1] is a reference. [$setname] (第1引数がリファレンスです)\n";
	}

	my $set;
	if(!defined($setname) || !length($setname)) {
		if($this->{default_set}) {
			$set = $this->{default_set};
		} else {
			die __PACKAGE__."#_getDbSetName: do not omit the DB Set because no default DB Set has been specified." .
				" (デフォルトの DB Set が指定されていない場合は、DB Set の指定を省略できません)\n";
		}
	} else {
		if($this->{dbh}{$setname}) {
			$set = $setname;
		} else {
			die __PACKAGE__."#_getDbSetName: DB set [$setname] was not defined. Please check the INI file.".
			" (DB Set [$setname] が存在しません)\n";
		}
	}

	$set;
}

sub _connect {
    # クラスメソッド。TL#startCgi，TL#trapErrorのみが呼ぶ。
    my $class = shift;
    my $groups = shift;

    foreach my $group (@$groups) {
        if (!defined $group) {
            die "TL#startCgi: -DB has an undefined value. (DB指定にundefが含まれます)\n";
        }
        elsif (ref $group) {
            die "TL#startCgi: -DB has a reference. (DB指定にリファレンスが含まれます)\n";
        }

        $INSTANCES{$group} = __PACKAGE__->_new($group)->connect;
    }

	# initRequest, postRequest, term をフックする
	$TL->setHook(
		'initRequest',
		_INIT_REQUEST_HOOK_PRIORITY,
		\&__initRequest,
	);

	$TL->setHook(
		'postRequest',
		_POST_REQUEST_HOOK_PRIORITY,
		\&__postRequest,
	);

	$TL->setHook(
		'term',
		_TERM_HOOK_PRIORITY,
		\&__term,
	);

	undef;
}

sub _new {
	my $class = shift;
	my $group = shift;

	my $this = bless {} => $class;
	$this->{group}     = $group;
	$this->{namequery} = $TL->INI->get($group => 'namequery' => undef);
	$this->{autoreyry} = $TL->INI->get($group => 'autoretry' => undef);
	$this->{type}      = $TL->INI->get($group => 'type');

	$this->{bufsize} = undef; # 正の値でなければ無制限
	$this->{types_symtable} = \%Tripletail::DB::SQL_TYPES::;

	$this->{dbh} = {};    # {DBセット名 => Tripletail::DB::Dbh}
	$this->{dbname} = {}; # {DBコネクション名 => Tripletail::DB::Dbh}

	$this->{default_set} = $TL->INI->get($group => 'defaultset', undef); # デフォルトのセット名

	$this->{locked_dbh}   = undef; # Tripletail::DB::Dbh
	$this->{trans_dbh}    = undef; # Tripletail::DB::Dbh

	do {
		local $SIG{__DIE__} = 'DEFAULT';
		eval q{
			package Tripletail::DB::SQL_TYPES;
			use DBI qw(:sql_types);
		};
	};
	if($@) {
		die $@;
	}

	# ここでセット定義を読む
	foreach my $setname ($TL->INI->getKeys($group)) {
		$setname =~ m/^[a-z]+$/ and next; # 予約済

		my @db = split /\s*,\s*/, $TL->INI->get($group => $setname);
		if (!scalar(@db)) {
			# ゼロ個のDBから構成されるDBセットを作ってはならない。
			die __PACKAGE__."#new: DB Set [$setname] has no databases. (DB Set [$setname] にDBが1つもありません)\n";
		}

        my $dbname = $db[$$ % scalar(@db)];
        if (!$this->{dbname}{$dbname}) {
            my $type    = $this->{type};
            my $backend = exists $BACKEND_OF{$type}
                               ? $BACKEND_OF{$type}
                               : die "TL#startCgi: DB type [$type] is not supported.".
                                 " (DB type [$type] はサポートされていません)\n";

            eval qq{
                use $backend;
            };
            if ($@) {
                local $SIG{__DIE__} = $@;
                die $@;
            }

            my $class = $backend . '::Dbh';
            $this->{dbname}{$dbname} = $class->new($setname, $dbname);
        }
        $this->{dbh}{$setname} = $this->{dbname}{$dbname};
	}

	$this;
}

sub __nameQuery {
	my $this = shift;
	my $query = shift;
	my $dbh = shift;

	if(!$this->{namequery}) {
		return $query;
	}

	# スタックを辿り、最初に現れたTripletail::DB以外のパッケージが作ったフレームを見て、
	# ファイル名と行番号を得る。
	for(my $i = 0;; $i++) {
		my ($pkg, $fname, $lineno) = caller $i;
		if($pkg !~ m/^Tripletail::DB/) {
			$fname =~ m!([^/]+)$!;
			$fname = $1;

			my $comment = sprintf '/* %s:%d [%s.%s.%s] */',
			$fname, $lineno, $this->{group}, $dbh->getSetName, $dbh->getGroup;

			$query =~ s/^(\s*\w+)/$1 $comment/;
			return $query;
		}
	}

	$query;
}

sub __initRequest {
	# %INSTANCESの中から、接続が確立していないものを接続する。
	foreach my $db (values %INSTANCES) {
		$db->connect;
	}
}

sub __term {
	# %INSTANCESの接続を切断する。
	foreach my $db (values %INSTANCES) {
		$db->disconnect;
	}
	%INSTANCES = ();
}

sub __postRequest {
	# %INSTANCESの中から、lockedのままになっているものに対して
	# UNLOCK TABLESを実行する。
	# また、トランザクションが済んでいないものについてはrollbackする。

	# 更にDBセットのデフォルト値を Ini の物にする

	foreach my $db (values %INSTANCES) {
		if(my $dbh = $db->{locked_dbh}) {
			$db->unlock;

			my $setname = $dbh->getSetName;
			$TL->log(
				__PACKAGE__,
				"DB [$db->{group}] (DB Set [$setname]) has been left locked after the last request.".
				" Tripletail::DB automatically unlocked it for safety.".
				" (DB [$db->{group}] (DB Set [$setname]) はロックしたままリクエスト処理を終えました。安全のため自動的にunlockしました)"
			);
		}
		if(my $dbh = $db->{trans_dbh}) {
			$db->rollback;

			my $setname = $dbh->getSetName;
			$TL->log(
				__PACKAGE__,
				"DB [$db->{group}] (DB Set [$setname]) has been left in transaction after the last request.".
				" Tripletail::DB automatically rollbacked it for safety.".
				" (DB [$db->{group}] (DB Set [$setname]) はトランザクション中のままリクエスト処理を終えました。安全のため自動的にrollbackしました)"
			);
		}

		$db->setDefaultSet($TL->INI->get($db->{group} => defaultset => undef));
	}
}

__END__

=encoding utf-8

=for stopwords
	CGI
	DBI
	Ini
	ini
	ODBC
	unixODBC
	TL
	SQL
	YMIRLINK
	mysql
	freetds
	mssql
	pgsql
	sqlite

=head1 NAME

Tripletail::DB - DBI のラッパ

=head1 SYNOPSIS

  $TL->startCgi(
      -DB      => 'DB',
      -main        => \&main,
  );
  
  sub main {
    my $DB = $TL->getDB('DB');
    
    $DB->setDefaultSet('R_Trans');
    $DB->tx(sub{
      my $sth = $DB->execute(q{SELECT a, b FROM foo WHERE a = ?}, 999);
      while (my $hash = $sth->fetchHash) {
        $TL->print($hash->{a});
      }
      # commit is done implicitly.
    });
    
    $DB->tx('W_Trans' => sub{
      $DB->execute(q{UPDATE counter SET counter = counter + 1 WHERE id = ?}, 1);
      $DB->commit; # can commit explicitly.
    }
  }

=head1 DESCRIPTION

=over 4

=item 接続/切断は自動で行われる。

手動で接続/切断する場合は、connect/disconnectを使うこともできるが、なるべく使用しないことを推奨。

=item 実行クエリの処理時間・実行計画・結果を記録するデバッグモード。

=item prepare/executeを分けない。fetchは分けることもできる。

=item 拡張プレースホルダ機能

  $db->execute(q{select * from a where mode in (??)}, ['a', 'b'])

と記述すると、

  $db->execute(q{select * from a where mode in (?, ?)}, 'a', 'b')

のように解釈される。

=item プレースホルダの値渡しの際に型指定が可能

  $db->execute(q{select * from a limit ??}, [10, \'SQL_INTEGER'])

型指定ができるのは拡張プレースホルダのみです.
通常の C<?> によるプレースホルダではエラーとなります.

=item リクエスト処理完了後のトランザクション未完了やunlock未完了を自動検出

=item DBグループ・DBセット・DBコネクション

Tripletail::DBでは、レプリケーションを利用してロードバランスすることを支援するため、
１つのDBグループの中に、複数のDBセットを定義することが可能となっている。
DBセットの中には、複数のDBコネクションを定義できる。

更新用DBセット、参照用DBセット、などの形で定義しておき、プログラム中で
トランザクション単位でどのDBセットを使用するか指定することで、
更新用クエリはマスタDB、参照用クエリはスレーブDB、といった
使い分けをすることが可能となる。

DBセットには複数のDBコネクションを定義でき、複数定義した場合は
プロセス単位でプロセスIDを元に1つのコネクションが選択される。
（プロセスIDを定義数で割り、その余りを使用して決定する。）

同じDBグループの中の複数のDBセットで同じDBコネクション名が使用された場合は、
実際にDBに接続されるコネクション数は1つとなる。
このため、縮退運転時に参照用DBセットのDBコネクションを更新用の
ものに差し替えたり、予め将来を想定して多くのDBセットに分散
させておくことが可能となっている。

DBセットの名称はSET_XXXX(XXXXは任意の文字列)でなければならない。 
DBコネクションの名称はCON_XXXX(XXXXは任意の文字列)でなければならない。

いずれのDBコネクションも利用可能である必要があり、
接続できなかった場合はエラーとなる。

DBのフェイルオーバーには（現時点では）対応していない。

=back

=head2 DBI からの移行

Tripletail の DB クラスは DBI に対するラッパの形となっており、多くのインタフェースは DBI のものとは異なる。
ただし、いつでも C<< $DB->getDbh() >> メソッドにより元の DBI オブジェクトを取得できるので、 DBI のインタフェースで利用することも可能となっている。

DBI のインタフェースは以下のようなケースで利用できる。
ただし、 DBI を直接利用する場合は、TLの拡張プレースホルダやデバッグ機能、トランザクション整合性の管理などの機能は利用できない。

=over 4

=item ラッパに同等の機能が用意されていない場合。

=item 高速な処理が必要で、ラッパのオーバヘッドを回避したい場合。

DBI に対するラッパであるため、大量の SQL を実行する場合などはパフォーマンス上のデメリットがある。

=back

DBI での SELECT は、以下のように置き換えられる。

 # DBI
 my $sth = $DB->prepare(q{SELECT * FROM test WHERE id = ?});
 $sth->execute($id);
 while(my $data = $sth->fetchrow_hashref) {
 }
 # TL
 my $sth = $DB->execute(q{SELECT * FROM test WHERE id = ?}, $id);
 while(my $data = $sth->fetchHash) {
 }

TL では prepare/execute は一括で行い、 prepared statement は利用できない。

C<INSERT>・C<UPDATE>は、以下のように置き換えられる。

 # DBI
 my $sth = $DB->prepare(q{INSERT INTO test VALUES (?, ?)});
 my $ret = $sth->execute($id, $data);
 # TL
 my $sth = $DB->execute(q{INSERT INTO test VALUES (?, ?)}, $id, $data);
 my $ret = $sth->ret;

prepare/execute を一括で行うのは同様であるが、 execute の戻り値はC<$sth>オブジェクトであり、影響した行数を取得するためには C<< $sth->ret >> メソッドを呼ぶ必要がある。

プレースホルダの型指定は以下のように行う。

 # DBI
 my $sth = $DB->prepare(q{SELECT * FROM test LIMIT ?});
 $sth->bind_param(1, $limit, { TYPE => SQL_INTEGER });
 $sth->execute;
 # TL
 my $sth = $DB->execute(q{SELECT * FROM test LIMIT ??}, [$limit, \'SQL_INTEGER']);

TLの拡張プレースホルダ（??で表記される）を利用し、配列のリファレンスの最後に型をスカラのリファレンスの形で渡す。
拡張プレースホルダでは、複数の値を渡すことも可能である。

 # DBI
 my $sth = $DB->prepare(q{SELECT * FROM test LIMIT ?, ?});
 $sth->bind_param(1, $limit, { TYPE => SQL_INTEGER });
 $sth->bind_param(2, $offset, { TYPE => SQL_INTEGER });
 $sth->execute;
 # TL
 my $sth = $DB->execute(q{SELECT * FROM test LIMIT ??}, [$limit, $offset, \'SQL_INTEGER']);

INSERTした行のAUTO_INCREMENT値の取得は、getLastInsertId で行える。

 # DBI
 my $id = $DB->{mysql_insertid};
 # TL
 my $id = $DB->getLastInsertId;

拡張ラッパでは制御できない機能にアクセスする場合などは、 DBI のハンドラを直接利用する。

 # DBI
 my $id = $DB->{RowCacheSize};
 # TL
 my $id = $DB->getDbh()->{RowCacheSize};

トランザクションには C<< $DB->tx(sub{...}) >> メソッドを用いる。
DBセットを指定する時には C<< $DB->tx(dbset_name=>sub{...}) >> となる。
渡したコードをトランザクション内で実行する。 
die なしにコードを抜けた時に自動的にコミットされる。 
途中で die した場合にはトランザクションはロールバックされる。 

 # DBI
 $DB->do(q{BEGIN WORK});
 #   do something.
 $DB->commit;
 
 # TL
 $DB->tx(sub{
   # do something.
 });

C<begin()> メソッドも実装はされているがその使用は非推奨である。 
また、 C<< $DB->execute(q{BEGIN WORK}); >> として利用することはできない。 

=head2 拡張プレースホルダ詳細

L</"execute"> に渡される SQL 文には、通常のプレースホルダの他に、
拡張プレースホルダ "??" を埋め込む事が出来る。
拡張プレースホルダの置かれた場所には、パラメータとして通常のスカラー値でなく、
配列へのリファレンスを与えなければならない。配列が複数の値を持っている場合には、
それらが通常のプレースホルダをカンマで繋げたものに展開される。

例: 以下の二文は等価

  $DB->execute(
      q{SELECT * FROM a WHERE a IN (??) AND b = ?},
      ['AAA', 'BBB', 'CCC'], 800);
  
  $DB->execute(
      q{SELECT * FROM a WHERE a IN (?, ?, ?) AND b = ?},
      'AAA', 'BBB', 'CCC', 800);

パラメータとしての配列の最後の項目が文字列へのリファレンスである時、その文字列は
SQL 型名として扱われる。配列が複数の値を持つ時には、その全ての要素に対して
型指定が適用される。型名はF<DBI.pm>で定義される。

例:

  $DB->execute(q{SELECT * FROM a LIMIT ??}, [20, \'SQL_INTEGER']);
  ==> SELECT * FROM a LIMIT 20
  
  $DB->execute(q{SELECT * FROM a LIMIT ??}, [20, 5, \'SQL_INTEGER']);
  ==> SELECT * FROM a LIMIT 20, 5

配列内の要素を更に2要素の配列とし、二番目の要素を文字列へのリファレンスと
する事で、要素の型を個別に指定出来る。

例:

  $DB->execute(
      q{SELECT * FROM a WHERE a IN (??) AND b = ?},
      [[100, \'SQL_INTEGER'], 'foo', \'SQL_VARCHAR'], 800);
  ==> SELECT * FROM a WHERE a IN (100, 'foo') AND b = '800'


=head2 METHODS

=head3 C<Tripletail::DB> メソッド

=over 4

=item C<< $TL->getDB >>

   $DB = $TL->getDB
   $DB = $TL->getDB($inigroup)

Tripletail::DB オブジェクトを取得。
引数には Ini で設定したグループ名を渡す。
引数省略時は 'DB' グループが使用される。

L<< $TL->startCgi|Tripletail/"startCgi" >> /  L<< $TL->trapError|Tripletail/"trapError" >> の関数内でDBオブジェクトを取得する場合に使用する。

=item C<< $TL->newDB >>

   $DB = $TL->newDB
   $DB = $TL->newDB($inigroup)

新しく Tripletail::DB オブジェクト作成。
引数には Ini で設定したグループ名を渡す。
引数省略時は 'DB' グループが使用される。

動的にコネクションを作成したい場合などに使用する。
この方法で Tripletail::DB オブジェクトを取得した場合、L<"connect"> / L<"disconnect"> を呼び出し、接続の制御を行う必要がある。

=item C<< connect >>

DBに接続する。

L<< $TL->startCgi|Tripletail/"startCgi" >> /  L<< $TL->trapError|Tripletail/"trapError" >> の関数内でDBオブジェクトを取得する場合には自動的に接続が管理されるため、このメソッドを呼び出してはならない。

L<< $TL->newDB|"$TL->newDB" >> で作成した Tripletail::DB オブジェクトに関しては、このメソッドを呼び出し、DBへ接続する必要がある。

C<connect>時には、C<AutoCommit> 及び C<RaiseError> オプションは 1 が指定され、C<PrintError> オプションは 0 が指定される。

=item C<< disconnect >>

DBから切断する。

L<< $TL->startCgi|Tripletail/"startCgi" >> /  L<< $TL->trapError|Tripletail/"trapError" >> の関数内でDBオブジェクトを取得する場合には自動的に接続が管理されるため、このメソッドを呼び出してはならない。

L<< $TL->newDB|"$TL->newDB" >> で作成した Tripletail::DB オブジェクトに関しては、このメソッドを呼び出し、DBへの接続を切断する必要がある。

=item C<< tx >>

  $DB->tx(sub{...})
  $DB->tx('SET_W_Trans' => sub{...})

指定されたDBセット名でトランザクションを開始し、その中でコードを
実行する。トランザクション名(DBセット名) は ini で定義されていな
ければならない。名前を省略した場合は、デフォルトのDBセットが使われるが、
setDefaultSetによってデフォルトが選ばれていない場合には例外を発生させる。

コードを die なしに終了した時にトランザクションは暗黙にコミットされる。
die した場合にはロールバックされる。
コードの中で明示的にコミット若しくはロールバックを行うこともできる。
明示的にコミット若しくはロールバックをした後は、 C<tx> を抜けるまで
DB 操作は禁止される。 この間の DB 操作は例外を発生させる。

=item C<< rollback >>

  $DB->rollback

現在実行中のトランザクションを取り消す。

=item C<< commit >>

  $DB->commit

現在実行中のトランザクションを確定する。

=item C<< inTx >>

  $DB->inTx() and die "double transaction";
  $DB->inTx('SET_W_Trans') or die "transaction required";

既にトランザクション中であるかを確認する。 
既にトランザクション中であれば真を、 
他にトランザクションが走っていなければ偽を返す。 
トランザクションの指定も可能。 
異なるDBセット名のトランザクションが実行中だった場合には
例外を発生させる。 

=item C<< begin >>

  $DB->begin
  $DB->begin('SET_W_Trans')

非推奨。L</tx> を使用のこと。

指定されたDBセット名でトランザクションを開始する。トランザクション名
(DBセット名) は ini で定義されていなければならない。
名前を省略した場合は、デフォルトのDBセットが使われるが、
setDefaultSetによってデフォルトが選ばれていない場合には例外を発生させる。

CGIの中でトランザクションを開始し、終了せずに Main 関数を抜けた場合は、自動的に
C<rollback>される。

トランザクション実行中にこのメソッドを呼んだ場合には、例外を発生させる。
1度に開始出来るトランザクションは、1つのDBグループにつき1つだけとなる。

=item C<< setDefaultSet >>

  $DB->setDefaultSet('SET_W_Trans')

デフォルトのDBセットを選択する。ここで設定されたDBセットは、引数無しのbegin()
や、beginせずに行ったexecuteの際に使われる。このメソッドは
L<Main 関数|Tripletail/"Main 関数"> の先頭で呼ばれる事を想定している。

=item C<< execute >>

  $DB->execute($sql, $param...)
  $DB->execute(\'SET_W_Trans' => $sql, $param...)

C<SELECT>/C<UPDATE>/C<DELETE>などの SQL 文を実行する。
第1引数に SQL 、第2引数以降にプレースホルダの引数を渡す。
ただし、第1引数にリファレンスでDBセットを渡すことにより、
トランザクション外での実行時にDBセットを指定することが可能。

第2引数以降の引数では、拡張プレースホルダが使用できる。
L</"拡張プレースホルダ詳細"> を参照。

既にトランザクションが実行されていれば、そのトランザクションの
DBセットで SQL が実行される。

トランザクションが開始されておらず、かつ L</"lock"> により
テーブルがロックされていれば、ロックをかけているDBセットで SQL が実行される。

いずれの場合でもない場合は、L</"setDefaultSet"> で指定された
トランザクションが使用される。
L</"setDefaultSet"> による設定がされていない場合は、例外を発生させる。

このメソッドを使用して、C<LOCK>/C<UNLOCK>/C<BEGIN>/C<COMMIT>といった SQL 文を
実行してはならない。実行しようとした場合は例外を発生させる。
代わりに専用のメソッドを使用する事。

=item C<< selectAllHash >>

  $DB->selectAllHash($sql, $param...)
  $DB->selectAllHash(\'SET_W_Trans' => $sql, $param...)

SELECT結果をハッシュの配列へのリファレンスで返す。
データがない場合は [] が返る。

  my $arrayofhash = $DB->selectAllHash($sql, $param...);
  foreach my $hash (@$arrayofhash){
     $TL->log(DBDATA => "name of id $hash->{id} is $hash->{name}");
  }

=item C<< selectAllArray >>

  $DB->selectAllArray($sql, $param...)
  $DB->selectAllArray(\'SET_W_Trans' => $sql, $param...)

SELECT結果を配列の配列へのリファレンスで返す。
データがない場合は [] が返る。

  my $arrayofarray = $DB->selectAllArray($sql, $param...);
  foreach my $array (@$arrayofarray){
     $TL->log(DBDATA => $array->[0]);
  }

=item C<< selectRowHash >>

  $DB->selectRowHash($sql, $param...)
  $DB->selectRowHash(\'SET_W_Trans' => $sql, $param...)

SELECT結果の最初の１行をハッシュへのリファレンスで返す。
実行後、内部でC<finish>する。
データがない場合は undef が返る。

  my $hash = $DB->selectRowHash($sql, $param...);
  $TL->log(DBDATA => "name of id $hash->{id} is $hash->{name}");

=item C<< selectRowArray >>

  $DB->selectRowArray($sql, $param...)
  $DB->selectRowArray(\'SET_W_Trans' => $sql, $param...)

SELECT結果の最初の１行を配列へのリファレンスで返す。
実行後、内部でC<finish>する。
データがない場合は undef が返る。

  my $array = $DB->selectRowArray($sql, $param...);
  $TL->log(DBDATA => $array->[0]);

=item C<< upsert >>

  $DB->upsert(
      'table1',
      {key1 => 'val1', key2 => 'val2'},  # $keys
      {val3 => 'val3', val4 => 'val4'}); # $values

  $DB->upsert(
      'schema1', # スキーマ名
      'table1',
      {key1 => 'val1', key2 => 'val2'},  # $keys
      {val3 => 'val3', val4 => 'val4'}); # $values

  $DB->upsert(
      \'SET_W_Trans',
      'table1',
      {key1 => 'val1', key2 => 'val2'},  # $keys
      {val3 => 'val3', val4 => 'val4'}); # $values

テーブルの特定の一行に対して UPDATE を実行し、もし該当行が存在しなければ
INSERT を実行するという処理を、たとえトランザクションの外で行われた場合であってもアトミックに行う。

与えられたテーブル名やスキーマ名は、内部で自動的に L<symquote> した上で SQL 文に埋め込まれる。

C<$keys> はテーブルの一意キー（通常は主キー）からその値へのハッシュテーブル。
その内容はテーブルの一意キーが渡っているカラムと一致していなければならない。
つまりこのキー集合によってテーブル上のカラムを常に一意に特定する事ができなければならない。

C<$values> はそれ以外のカラム名からその値へのハッシュテーブルであり、省略も可能。
上記の例に挙げたコードは、まず次のような UPDATE 文を実行し、

  UPDATE table1
     SET val3 = 'val3', val4 = 'val4'
   WHERE key1 = 'val1', key2 = 'val2'

該当する行が存在しなければ次のような INSERT 文を実行する。

  INSERT INTO table1
              ( key1 ,  key2 ,  val3 ,  val4 )
       VALUES ('val1', 'val2', 'val3', 'val4')

現在 pgsql のみで利用可能。


=item C<< findTables >>

  my $sth = $DB->findTables({
                set    => 'SET_W_Trans', # 省略可能
                schema => 'schema',      # 省略可能
                table  => 'table\\_%'    # 省略可能
              });
  while (my $row = $sth->fetchHash) {
      print $row->{TABLE_NAME}, "\n";
  }

データベース内に存在するテーブルの一覧を得るための C<Tripletail::DB::Sth> オブジェクトを返す。

スキーマ名やテーブル名に C<< _ >> または C<< % >> 記号が含まれていた場合は、その文字列は
LIKE 演算子のワイルドカードと見倣される。省略も可能であり、その場合は全てのスキーマ名または全てのテーブル名にマッチする
C<< '%' >> が指定された場合と同様の結果になる。C<undef> の場合も同様。

このメソッドにより得られた C<Tripletail::DB::Sth> オブジェクトの返す各行は
C<< DBI->table_info() >> と同等である。詳しくは
L<http://search.cpan.org/dist/DBI/DBI.pm#table_info> を参照。


=item C<< getTableColumns >>

  my $columns_ref = $DB->getTableColumns(\'SET_W_Trans', 'schema', 'table');
  my $columns_ref = $DB->getTableColumns(\'SET_W_Trans', 'table');
  my $columns_ref = $DB->getTableColumns('schema', 'table');
  my $columns_ref = $DB->getTableColumns('table');

  if ($columns_ref) {
      foreach my $column_ref (@$columns_ref) {
          printf(
              "%s :: %s\n",
              $column_ref->{ COLUMN_NAME },
              $column_ref->{ TYPE_NAME   });
      }
  }
  else {
      print "table not found\n";
  }

テーブルの持つカラムの一覧を、ハッシュリファレンスを要素とする配列リファレンスで返す。
その要素であるカラム情報は C<< DBI->column_info() >> から得られるものと同等である。
詳しくは L<http://search.cpan.org/dist/DBI/DBI.pm#column_info> を参照。

指定されたテーブルが存在しない場合、このメソッドは C<undef> を返す。


=item C<< lock >>

  $DB->lock(set => 'SET_W_Trans', read => ['A', 'B'], write => 'C')

指定されたDBセットに対してC<LOCK TABLES>を実行する。C<set>が省略された場合はデフォルト
のDBセットが選ばれる。 CGI の中でロックした場合は、 L<Main 関数|Tripletail/"Main 関数">
を抜けた時点で自動的に unlock される。

ロック実行中にこのメソッドを呼んだ場合には、例外を発生させる。
1度に開始出来るロックは、1つのDBグループにつき1つだけとなる。

現在 mysql でのみ使用可能.

mysql ではロック中にテーブルのエイリアスを使用する場合、エイリアスに対してもロックを指定する必要がある。これを行うには、テーブル名の文字列の替わりにハッシュのリファレンス {'テーブル名' => 'エイリアス'} を指定する。次に、テーブル sample とそのエイリアス A, B をロックする例を示す。

  $DB->lock(read => ['sample', {'sample' => 'A'}, {'sample' => 'B'}]);
  $DB->execute(q{
    SELECT sample.nval, A.nval as A, B.nval as B 
    FROM sample, sample AS A, sample AS B 
    WHERE sample.nval + 1 = A.nval AND A.nval + 1 = B.nval
  });
  $DB->unlock;

=item C<< unlock >>

  $DB->unlock

C<UNLOCK TABLES> を実行する。
ロックがかかっていない場合は例外を発生させる。

現在 mysql でのみ使用可能.

=item C<< setBufferSize >>

  $DB->setBufferSize($kbytes)

バッファサイズをKB単位でセットする。行を１行読み込んだ結果
このサイズを上回る場合、C<< die >>する。
C<< 0 >> または C<< undef >> をセットすると、制限が解除される。

=item C<< quote >>

  $DB->quote($literal)

文字列をリテラルとしてクォートする。

通常 C<< 'a b c' >> のようにシングルクオートで文字列が囲まれる。

=item C<< symquote >>

  $DB->symquote($sym)

文字列を識別子としてクォートする。

mysql の場合は C<< `a b c` >> となり、それ以外の場合は C<< "a b c" >> となる。

=item C<< escapeLike >>

  $DB->escapeLike($pattern)

与えられた文字列を LIKE 演算子のパターンと見倣して、そのワイルドカード記号をエスケープする。
エスケープの方法は各データベースエンジンによって異なるが、多くの場合は次の式が成立する。

  $DB->escapeLike('foo') eq 'foo'
  $DB->escapeLike('f_o') eq 'f\\_o'
  $DB->escapeLike('f%o') eq 'f\\%o'
  $DB->escapeLike('f\\') eq 'f\\\\'

=item C<getType>

  $DB->getType;

DBのタイプを返す。C<< (mysql, pgsql, ...) >>

=item C<getDbh>

  $dbh = $DB->getDbh
  $dbh = $DB->getDbh('SET_W_Trans')

DBセット内のDBハンドルを返す。
返されるオブジェクトは L<DBI> ネイティブのC<dbh>である。

ネイティブのDBハンドルを使用してクエリを発行した場合、デバッグ機能（プロファイリング等）の機能は使用できません。
また、トランザクションやロック状態の管理もフレームワークで行えなくなるため、注意して使用する必要があります。

=item C<getLastInsertId>

  $id = $DB->getLastInsertId()

セッション内の最後の自動採番の値を取得. 

=back

=head3 C<Tripletail::DB::Sth> メソッド

=over 4

=item C<< fetchHash >>

  $sth->fetchHash

ハッシュへのリファレンスで１行取り出す。

=item C<< fetchArray >>

  $sth->fetchArray

配列へのリファレンスで１行取り出す。

=item C<< ret >>

  $sth->ret

最後に実行した execute の戻り値を返す。

=item C<< rows >>

  $sth->rows

DBI と同様。

=item C<< finish >>

  $sth->finish

DBI と同様。

=item C<< nameArray >>

  $sth->nameArray

C<< $sth->{NAME_lc} >> を返す。

=item C<< nameHash >>

  $sth->nameHash

C<< $sth->{NAME_lc_hash} >> を返す。

=back


=head2 Ini パラメータ

=head3 DBセット・DBコネクション

DBグループのパラメータのうち、半角小文字英数字のみで構成された
パラメータは予約済みで、DBグループの動作設定に使用する。
DBセットは、予約済みではない名前であれば任意の名称が使用でき、
値としてDBコネクションのINIグループ名をカンマ区切りで指定する。

例:

  [DB]
  namequery=1
  autoretry=1
  type=mysql
  defaultset=SET_R_Trans
  SET_W_Trans=CON_DBW1
  SET_R_Trans=CON_DBR1,CON_DBR2
  
  [CON_DBW1]
  dbname=test
  user=daemon
  host=192.168.0.100
  
  [CON_DBR1]
  dbname=test
  user=daemon
  host=192.168.0.110
  
  [CON_DBR2]
  dbname=test
  user=daemon
  host=192.168.0.111

以下は特別なパラメータ:

=over 4

=item C<< namequery >>

  namequery = 1

これを1にすると、実行しようとしたクエリのコマンド名の直後に
C<< /* foo.pl:111 [DB.R_Transaction1.DBR1] */ >> のようなコメントを挿入する。
デフォルトは0。

=item C<< autoretry >>

  autoretry = 1

これを 1 にすると L</"tx"> を用いて実行されたトランザクションがデッドロックにより失敗した場合に自動的にトランザクションを再実行する。
データベースがデッドロック検出機構を持っていない場合には再実行は行われない。デフォルトは 0。

なお単体の L</"execute"> がデッドロックを起こした場合には、この設定とは無関係に必ず再実行される。

=item C<< type >>

  type = mysql

DBの種類を選択する。
mysql, pgsql, oracle, interbase, sqlite, mssql が使用可能。
必須項目。

=item C<< defaultset >>

  defaultset = SET_W_Trans

デフォルトのDBセットを設定する。
ここで設定されたDBセットは、引数無しのbegin()や、beginせずに行ったexecuteの際に使われる。

=back


=head3 DB定義

=over 4

=item C<< dbname >>

  dbname = test

DB名を設定する。

=item C<< host >>

  host = localhost

DBのアドレスを設定する。
デフォルトはC<localhost>。

=item C<< user >>

  user = www

DBに接続する際のユーザー名を設定する。

=item C<< password >>

  password = PASS

DBに接続する際のパスワードを設定する。
省略可能。

=item C<< mysql_read_default_file >>

  mysql_read_default_file = .../tl_mysql.cnf

mysql クライアントライブラリが使用する設定ファイル my.cnf のパスを指定する。
パスの指定を .../ で始めることで、 ini ファイルからの相対パスとして指定する事も可能。
設定ファイルを使用する事で、 default-character-set 等の Tripletail::DB や DBD::mysql からは設定できない項目が設定できる。
また、設定ファイルで user, password, host 等の値を指定する場合は、 Ini パラメータ のDBコネクションの値を省略する事ができる。(dbname だけは省略できない)

=item C<< mysql_read_default_group >>

  mysql_read_default_group = tripletail

mysql_read_default_file 指定時に、設定ファイル中のどのグループを使用するかを指定する。
グループを指定した場合は、 [client] グループの設定と指定したグループの設定の両方が有効になる。
グループを指定しない場合、 [client] グループの設定のみが有効となる。

=back

=head3 SQL Server 設定

試験的に SQL Server との接続が実装されています.
DBD::ODBC と, Linux であれば unixODBC + freetds で, Windows であれば
組み込みの ODBC マネージャで動作します.

設定例:
 
 # <tl.ini>
 [DB]
 type=mssql
 defaultset=SET_W_Trans
 SET_W_Trans=CON_RW
 [CON_RW]
 # dbname に ODBC-dsn を設定.
 dbname=test
 user=test
 password=test
 # freetds経由の時は, そちらのServernameも指定.
 tdsname=tds_test

freetds での接続文字コードの設定は F<freetds.conf> で
設定します. 

 ;; <freetds.conf>
 [tds_test]
 host = 10.0.0.1
 ;;port = 1433
 tds version = 7.0
 client charset = UTF-8

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
