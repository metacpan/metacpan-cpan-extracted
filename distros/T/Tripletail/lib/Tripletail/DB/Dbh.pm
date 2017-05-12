package Tripletail::DB::Dbh;
use strict;
use warnings;
use Hash::Util qw(lock_hash);

sub new {
    my $class   = shift;
    my $setname = shift;
    my $dbname  = shift;

    my $this = bless {} => $class;
    $this->{setname } = $setname;
    $this->{inigroup} = $dbname;
    $this->{dbh     } = undef; # DBI-dbh
    $this->{type    } = undef; # set on connect().

    $this;
}

sub getSetName {
    return shift->{setname};
}

sub getGroup {
    return shift->{inigroup};
}

sub getDbh {
    return shift->{dbh};
}

sub ping {
    my $this = shift;

    if ($this->{dbh}) {
        return $this->{dbh}->ping;
    }
    else {
        return;
    }
}

sub getLastInsertId {
    my $this = shift;

    my $type = $this->{type};
    die __PACKAGE__."#getLastInsertId: $type is not supported. (${type}はサポートされていません)";
}

sub quote {
    my $this = shift;
    my $str  = shift;

    if (!defined $str) {
        die __PACKAGE__."#quote: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $str) {
        die __PACKAGE__."#quote: arg[1] is a reference. [$str] (第1引数がリファレンスです)\n";
    }

    return $this->{dbh}->quote($str);
}

sub symquote {
    my $this = shift;
    my $str  = shift;

    if (!defined $str) {
        die __PACKAGE__."#symquote: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $str) {
        die __PACKAGE__."#symquote: arg[1] is a reference. [$str] (第1引数がリファレンスです)\n";
    }

    return $this->{dbh}->quote_identifier($str);
}

sub escapeLike {
    my $this = shift;
    my $str  = shift;

    if (!defined $str) {
        die __PACKAGE__."#symquote: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $str) {
        die __PACKAGE__."#symquote: arg[1] is a reference. [$str] (第1引数がリファレンスです)\n";
    }

    return $this->_escapeLike($str);
}

sub _escapeLike {
    # Subclasses may override this method.
    my $this = shift;
    my $str  = shift;

    $str =~ s/([_'%\\])/\\$1/g;
    return $str;
}

sub _mk_locking_query {
    my $this   = shift;
    my $tables = shift;

    my $type = $this->{type};
    die "Tripletail::DB#lock: DB type [$type] is not supported. (DB type [$type] に対する lock はサポートされていません)\n";
}

sub _mk_unlocking_query {
    my $this = shift;

    my $type = $this->{type};
    die "Tripletail::DB#unlock: DB type [$type] is not supported. (DB type [$type] に対する unlock はサポートされていません)\n";
}

sub disconnect {
    my $this = shift;

    $this->{dbh} and $this->{dbh}->disconnect;
    $this->{dbh}  = undef; # DBI-dbh
    $this->{type} = undef; # set on connect().
    $this;
}

sub begin {
    return shift->{dbh}->begin_work;
}

sub rollback {
    return shift->{dbh}->rollback;
}

sub commit {
    return shift->{dbh}->commit;
}

sub _mk_upsert_query {
    my $this   = shift;
    my $schema = shift;
    my $table  = shift;
    my $keys   = shift;
    my $values = shift;

    die __PACKAGE__."#upsert, this operation is not supported on DB type [$this->{type}]".
      " (この DB タイプでは upsert 処理はサポートされていません。)\n";
}

# エラー時に, DB別固有エラー情報から共通エラー情報に変換.
# 全てのDB種別で実装されているわけではない.
# 実装されていなければ常に COMMON_ERROR 扱い.
sub _errinfo {
    my $this = shift;
    my $dbh  = shift || $this->{dbh};

    $dbh or die __PACKAGE__."#_errinfo, no dbh. (dbhがありません)";

    my $error_info = $this->_last_error_info($dbh);
    return $this->_errinfo2(
        $error_info->{errkey}, # 共通のエラー識別キー.
        $error_info->{errno }, # DB固有のエラーコード.
        $error_info->{errstr}, # DB固有のエラーメッセージ.
       );
}

sub _last_error_info {
    my $this = shift;
    my $dbh  = shift || $this->{dbh};

    return +{
        errno  => $dbh->err,
        errstr => $dbh->errstr,
        errkey => 'COMMON_ERROR'
       };
}

# 共通エラーコードの可読メッセージ.
my %ERROR_MESSAGE_OF = (
    ACCESS_DENIED             => 'Access denied (アクセス権限がありません)',
    ALREADY_EXISTS            => 'Already exists (処理対象が既に存在します)',
    COMMON_ERROR              => 'Error (何らかのエラー)',
    CONNECT_DENIED            => 'Connection denied (接続する権限がありません)',
    CONNECT_NO_SERVER         => 'No server to connect (接続先サーバが存在しません)',
    CONNECT_PROTOCOL_MISMATCH => 'Connection protocol mismatch (接続プロトコルが一致しません)',
    DEADLOCK_DETECTED         => 'Deadlock detected (デッドロックが検出されました)',
    NO_ERROR                  => 'Success (処理成功)',
    NO_SUCH_OBJECT            => 'No such object (処理対象が存在しません)',
    SYNTAX_ERROR              => 'Syntax error (構文エラー)',
   );
lock_hash %ERROR_MESSAGE_OF;

sub _errinfo2 {
    my $this   = shift;
    my $errkey = shift || 'COMMON_ERROR';
    my $errno  = shift;
    my $errstr = shift;

    my $errmsg = $ERROR_MESSAGE_OF{$errkey};
    my ($errmsg_en, $errmsg_ja) = $errmsg =~ /^(.*) \((.*)\)\z/ or die "invalid message format: $errmsg";

    return +{
        $errkey   => $errmsg,
        _key      => $errkey,
        _msg      => $errmsg,
        _msg_en   => $errmsg_en,
        _msg_ja   => $errmsg_ja,
        _dbtype   => $this->{type},
        _dberrno  => $errno,
        _dberrstr => $errstr,
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Dbh - 内部用

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<< new >>

=item C<< begin >>

=item C<< commit >>

=item C<< rollback >>

=item C<< disconnect >>

=item C<< getDbh >>

=item C<< getGroup >>

=item C<< getLastInsertId >>

=item C<< getSetName >>

=item C<< ping >>

=item C<< quote >>

=item C<< symquote >>

=item C<< escapeLike >>

=back

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
