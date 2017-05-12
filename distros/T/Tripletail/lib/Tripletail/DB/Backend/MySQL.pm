package Tripletail::DB::Backend::MySQL::Dbh;
use strict;
use warnings;
use Hash::Util qw(lock_hash);
use Scalar::Lazy;
use Tripletail;
our @ISA = qw(Tripletail::DB::Dbh);

sub connect {
    my $this = shift;

    my $opts = {
        dbname => $TL->INI->get($this->{inigroup} => 'dbname'),
    };

    my $host = $TL->INI->get($this->{inigroup} => 'host' => undef);
    if (defined($host) && $host ne '') {
        $opts->{host} = $host;
    }

    my $port = $TL->INI->get($this->{inigroup} => 'port' => undef);
    if (defined($port) && $port ne '') {
        $opts->{port} = $port;
    }

    # mysql_read_default_file, mysql_read_default_group オプションを渡す
    if (defined(my $default_file = $TL->INI->get_reloc($this->{inigroup} => 'mysql_read_default_file' => undef))) {
        if (!-e $default_file) {
            die __PACKAGE__."#connect: file $default_file does not exist. ($default_file が存在しません)".
              " ('mysql_read_default_file' in [$this->{inigroup}])\n";
        }
        $opts->{mysql_read_default_file} = $default_file;

        if (defined(my $default_group = $TL->INI->get($this->{inigroup} => 'mysql_read_default_group' => undef))) {
            $opts->{mysql_read_default_group} = $default_group;
        }
    }

    no warnings 'redefine';
    if (!$DBI::installed_drh{mysql}) {
        DBI->install_driver('mysql');
    }
    my $orig = \&DBD::mysql::db::_login;
    local $Tripletail::Error::LAST_DB_ERROR;
    local *DBD::mysql::db::_login = sub {
        my @ret = wantarray ? &$orig : scalar(&$orig);
        if (!$ret[0]) {
            # $_[0]がdbh.
            # 保持してしまうとその後のエラーメッセージがでなくなり,
            # リファレンスではundefに消されてしまうので
            # ここでエラー情報を作成.
            $Tripletail::Error::LAST_DB_ERROR = lazy { $this->_errinfo($_[0]) } 'init';
        }
        return wantarray ? @ret : $ret[0];
    };

    $this->{type} = 'mysql';
    $this->{dbh } = DBI->connect(
        'dbi:mysql:' . join(';', map { "$_=$opts->{$_}" } keys %$opts),
        $TL->INI->get($this->{inigroup} => 'user'    , undef),
        $TL->INI->get($this->{inigroup} => 'password', undef), {
            AutoCommit => 1,
            PrintError => 0,
            RaiseError => 1,
        });

    if (!$this->{dbh}) {
        die __PACKAGE__."#connect: DBI->connect failed. (DBI->connectに失敗しました)\n";
    }

    return $this;
}

sub _mk_locking_query {
    my $this   = shift;
    my $tables = shift;

    return 'LOCK TABLES ' .
      join(
          ', ',
          map {
              my $table = $_->[0];
              my $alias = $_->[1];
              my $mode  = $_->[2];

              defined $alias
                ? sprintf(
                    '%s AS %s %s',
                    $this->symquote($table),
                    $this->symquote($alias),
                    $mode
                   )
                : sprintf(
                    '%s %s',
                    $this->symquote($table),
                    $mode
                   );
          } @$tables);
}

sub _mk_unlocking_query {
    my $this = shift;

    return 'UNLOCK TABLES';
}

sub getLastInsertId {
    my $this = shift;
    my $obj  = shift;

    return $this->{dbh}{mysql_insertid};
}

# エラー情報のDB別固有エラーコードから共通コードへのマッピング(mysql).
my %ERROR_KEY_OF = (
    # http://dev.mysql.com/doc/refman/5.0/en/error-messages-server.html
    # http://dev.mysql.com/doc/refman/5.0/en/error-messages-client.html
    0    => 'NO_ERROR',
    1044 => 'ACCESS_DENIED',
    1045 => 'CONNECT_DENIED',
    1050 => 'ALREADY_EXISTS',
    1064 => 'SYNTAX_ERROR',
    1146 => 'NO_SUCH_OBJECT',
    1149 => 'SYNTAX_ERROR',
    1213 => 'DEADLOCK_DETECTED',
    1251 => 'CONNECT_PROTOCOL_MISMATCH',
    1614 => 'DEADLOCK_DETECTED',
    2002 => 'CONNECT_NO_SERVER',
    2003 => 'CONNECT_NO_SERVER',
    2005 => 'CONNECT_NO_SERVER',
   );
lock_hash %ERROR_KEY_OF;

sub _last_error_info {
    my $this = shift;
    my $dbh  = shift || $this->{dbh};

    return +{
        errno  => $dbh->{mysql_errno},
        errstr => $dbh->{mysql_error},
        errkey => (exists $ERROR_KEY_OF{ $dbh->{mysql_errno} }
                        ? $ERROR_KEY_OF{ $dbh->{mysql_errno} }
                        : 'COMMON_ERROR')
       };
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Backend::MySQL - 内部用

=head1 SEE ALSO

L<Tripletail::DB>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2011 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
