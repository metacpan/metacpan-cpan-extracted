package Tripletail::Session::PgSQL;
use strict;
use warnings;
use Tripletail;
our @ISA = qw(Tripletail::Session);

sub _insertSid {
    my $this        = shift;
    my $checkval    = shift;
    my $checkvalssl = shift;
    my $data        = shift;

    my $DB = $TL->getDB($this->{dbgroup});

    my $sth = $DB->execute(
        \$this->{dbset},
        sprintf(
            q{INSERT INTO %s
                     (checkval, checkvalssl, data, updatetime)
              VALUES (       ?,           ?,    ?,      NOW())
              RETURNING sid},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $checkval, $checkvalssl, $data);

    return $sth->fetchArray->[0];
}

sub _createSessionTable {
    my $this = shift;

    # THINKME: PostgreSQL 9.0 以前では CREATE TABLE IF NOT EXISTS が使
    # えないため、以下のような方法で atomic に同様の動作を実現しようと
    # していたが、ログに不要な NOTICE が毎回出力されるので都合が悪かっ
    # た。9.1 前提になるまではセッションテーブルの自動生成はしない事に
    # した。
    # 追記: 9.1/CREATE TABLE IF NOT EXISTS であってもalready existsの
    # ログが1行ではあるが出力される.

    return $this;
}

=pod

sub _createSessionTable {
    my $this = shift;

    my $DB    = $TL->getDB($this->{dbgroup});
    my $table = $DB->symquote($this->{sessiontable}         , $this->{dbset});
    my $index = $DB->symquote($this->{sessiontable} . '_idx', $this->{dbset});

    # PostgreSQL: 9223372036854775807. (64bit/signed)
    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{DO $$
                     BEGIN
                         CREATE TABLE %s (
                             sid         BIGSERIAL NOT NULL,
                             checkval    BIGINT    NOT NULL,
                             checkvalssl BIGINT    NOT NULL,
                             data        BIGINT,
                             updatetime  TIMESTAMP NOT NULL,

                             PRIMARY KEY (sid)
                         );
                         CREATE INDEX %s ON %s (updatetime);
                     EXCEPTION WHEN duplicate_table THEN
                     END;
                 $$},
            $table, $index, $table));

    return $this;
}

=cut

sub _loadSession {
    my $this     = shift;
    my $sid      = shift;
    my $checkval = shift;
    my %opts     = @_;

    my $DB      = $TL->getDB($this->{dbgroup});
    my $colname = ($opts{secure} ? 'checkvalssl' : 'checkval');

    my $sessiondata = $DB->selectRowArray(
        \$this->{readdbset},
        sprintf(
            q{SELECT TEXT(data), date_part('epoch', updatetime), TEXT(checkval), TEXT(checkvalssl)
                FROM %s
               WHERE sid = ? AND %s = ?},
            $DB->symquote($this->{sessiontable}, $this->{readdbset}),
            $colname),
        $sid,
        $checkval);

    if (!defined $sessiondata) {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "The session is invalid: its session ID may not exist, or the checkval is invalid for the session: sid [$sid] checkval [$checkval] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
        }
    }
    elsif (time - $sessiondata->[1] > $this->{timeout_period}) {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "The session is invalid: it has been expired: sid [$sid] checkval [$checkval] updatetime [$sessiondata->[1]] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
        }
    }
    else {
        $this->{sid        } = $sid;
        $this->{data       } = $sessiondata->[0];
        $this->{updatetime } = $sessiondata->[1];
        $this->{checkval   } = $sessiondata->[2];
        $this->{checkvalssl} = $sessiondata->[3];
    }

    if (defined $this->{sid}) {
        my $datalog = (defined($this->{data}) ? $this->{data} : '(undef)');
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "Succeeded to read a valid session data. secure [$opts{secure}] sid [$this->{sid}] checkval [$this->{checkval}] checkvalssl [$this->{checkvalssl}] data [$datalog] updatetime [$this->{updatetime}] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
        }
    }
    else {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "Failed to read a valid session data. secure [$opts{secure}] sid [$sid] $colname [$checkval] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
        }
    }

    return $this;
}

sub _updateSession {
    my $this = shift;

    if (!defined($this->{updatetime})) {
        return $this;
    }

    if (time - $this->{updatetime} < $this->{updateinterval_period}) {
        return $this;
    }

    my $DB = $TL->getDB($this->{dbgroup});
    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{UPDATE %s
                 SET updatetime = NOW(), data = ?
               WHERE sid = ?},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $this->{data},
        $this->{sid});

    $this->{updatetime} = time;

    my $datalog = (defined($this->{data}) ? $this->{data} : '(undef)');
    if ($TL->INI->get($this->{group} => 'logging', '0')) {
        $TL->log(__PACKAGE__, "The session got updated. sid [$this->{sid}] data [$datalog] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
    }

    return $this;
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::Session::PgSQL - 内部用

=head1 SEE ALSO

L<Tripletail::Session>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2011 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
