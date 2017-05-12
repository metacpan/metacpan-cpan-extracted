package Tripletail::Session::SQLite;
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

    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{INSERT INTO %s
                     ( sid, checkval, checkvalssl, data,        updatetime)
              VALUES (NULL,        ?,           ?,    ?, CURRENT_TIMESTAMP)},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $checkval, $checkvalssl, $data);

    return $DB->getLastInsertId(\$this->{dbset});
}

sub _deleteSid {
    my $this = shift;
    my $sid  = shift;

    my $DB   = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{UPDATE %s
                 SET checkval    = 'x',
                     checkvalssl = 'x',
                     data        = NULL,
                     updatetime  = CURRENT_TIME
               WHERE sid = ?},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $sid);

    return $this;
}

sub _createSessionTable {
    my $this = shift;

    my $DB = $TL->getDB($this->{dbgroup});

    $TL->eval(
        sub {
            $DB->execute(
                \$this->{readdbset},
                sprintf(
                    q{SELECT * FROM %s LIMIT 0},
                    $DB->symquote($this->{sessiontable}, $this->{readdbset})));
        });
    if ($@) {
        # sqlite3: 9223372036854775807. (64bit/signed)
        my $table = $DB->symquote($this->{sessiontable}         , $this->{dbset});
        my $index = $DB->symquote($this->{sessiontable} . '_idx', $this->{dbset});
        $DB->execute(
            \$this->{dbset},
            sprintf(
                q{CREATE TABLE %s (
                      sid         INTEGER NOT NULL,
                      checkval    BLOB    NOT NULL,
                      checkvalssl BLOB    NOT NULL,
                      data        BLOB,
                      updatetime  TIMESTAMP NOT NULL,

                      PRIMARY KEY (sid)
                  )}, $table));
        $DB->execute(
            \$this->{dbset},
            sprintf(
                q{CREATE INDEX %s ON %s (updatetime)},
                $index, $table));
    }

    return $this;
}

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
            q{SELECT data, datetime(updatetime, 'localtime'), checkval, checkvalssl
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
    elsif ($sessiondata->[2] eq 'x' || $sessiondata->[3] eq 'x') {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "The session is invalid: it has a deletion mark: sid [$sid] checkval [$$sessiondata->[0][2]] checkvalssl [$$sessiondata->[0][3]] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
        }
    }
    else {
        my $updatetime = $TL->newDateTime($sessiondata->[1])->getEpoch();
        if (time - $updatetime > $this->{timeout_period}) {
            if ($TL->INI->get($this->{group} => 'logging', '0')) {
                $TL->log(__PACKAGE__, "The session is invalid: it has been expired: sid [$sid] checkval [$checkval] updatetime [$sessiondata->[1]] on the DB [$this->{dbgroup}][$this->{sessiontable}].");
            }
        }
        else {
            $this->{sid        } = $sid;
            $this->{data       } = $sessiondata->[0];
            $this->{updatetime } = $updatetime;
            $this->{checkval   } = $sessiondata->[2];
            $this->{checkvalssl} = $sessiondata->[3];
        }
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
                 SET updatetime = CURRENT_TIMESTAMP, data = ?
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

Tripletail::Session::SQLite - 内部用

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
