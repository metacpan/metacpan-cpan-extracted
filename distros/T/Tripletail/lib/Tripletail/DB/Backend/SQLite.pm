package Tripletail::DB::Backend::SQLite::Dbh;
use strict;
use warnings;
use Hash::Util qw(lock_hash);
use Scalar::Lazy;
use Tripletail;
our @ISA = qw(Tripletail::DB::Dbh);

sub connect {
    my $this = shift;

    my $opts = {
        dbname => $TL->INI->get_reloc($this->{inigroup} => 'dbname'),
    };

    no warnings 'redefine';
    $DBI::installed_drh{SQLite} or DBI->install_driver('SQLite');
    my $orig = \&DBD::SQLite::db::_login;
    local $Tripletail::Error::LAST_DB_ERROR;
    local *DBD::SQLite::db::_login = sub{
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

    $this->{type} = 'sqlite';
    $this->{dbh } = DBI->connect(
        'dbi:SQLite:' . join(';', map { "$_=$opts->{$_}" } keys %$opts),
        $TL->INI->get($this->{inigroup} => 'user'     => undef),
        $TL->INI->get($this->{inigroup} => 'password' => undef), {
            AutoCommit => 1,
            PrintError => 0,
            RaiseError => 1,
        });

    if (!$this->{dbh}) {
        die __PACKAGE__."#connect: DBI->connect failed. (DBI->connectに失敗しました)\n";
    }

    return $this;
}

sub getLastInsertId {
    my $this = shift;
    my $obj  = shift;

    return $this->{dbh}->func('last_insert_rowid');
}

# エラー情報のDB別固有エラーコードから共通コードへのマッピング(sqlite).
my %ERROR_KEY_OF = (
    # http://www.sqlite.org/c3ref/c_abort.html
    0 => 'NO_ERROR',
    5 => 'DEADLOCK_DETECTED',
    6 => 'DEADLOCK_DETECTED'
   );
lock_hash %ERROR_KEY_OF;

sub _last_error_info {
    my $this = shift;
    my $dbh  = shift || $this->{dbh};

    my $errno  = $dbh->err || 0;
    my $errstr = $dbh->errstr;
    my $errkey = (exists $ERROR_KEY_OF{$errno}
                       ? $ERROR_KEY_OF{$errno}
                       : 'COMMON_ERROR');

    if ($errno == 1) {
        # ちゃんとエラー番号が返ってこない?
        if ($errstr =~ /^no such table:/) {
            $errkey = 'NO_SUCH_OBJECT';
        }
        elsif ($errstr =~ /^unable to open database file/) {
            $errkey = $!{EACCES} ? 'CONNECT_DENIED' : 'CONNECT_NO_SERVER';
        }
        elsif ($errstr =~ /^attempt to write a readonly database/) {
            $errkey = 'ACCESS_DENIED';
        }
    }

    return +{
        errno  => $errno,
        errstr => $errstr,
        errkey => $errkey
       };
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Backend::SQLite - 内部用

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
