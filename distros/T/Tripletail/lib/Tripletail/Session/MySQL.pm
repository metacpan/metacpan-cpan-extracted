package Tripletail::Session::MySQL;
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
                     ( sid, checkval, checkvalssl, data)
              VALUES (NULL,        ?,           ?,    ?)},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $checkval, $checkvalssl, $data);

    return $DB->getLastInsertId(\$this->{dbset});
}

sub _createSessionTable {
    my $this = shift;

    my $DB = $TL->getDB($this->{dbgroup});

    my $table_type  = $TL->INI->get($this->{group} => mysqlsessiontabletype => undef);
    my $type_option = defined $table_type && $table_type =~ m/^[a-z]+$/i
                            ? 'TYPE = ' . $table_type
                            : '';

    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{CREATE TABLE IF NOT EXISTS %s (
                  sid         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  checkval    BIGINT UNSIGNED NOT NULL,
                  checkvalssl BIGINT UNSIGNED NOT NULL,
                  data        BIGINT UNSIGNED,
                  updatetime  TIMESTAMP NOT NULL,

                  PRIMARY KEY (sid),
                  INDEX (updatetime)
              )
              AUTO_INCREMENT = 4294967296
              MAX_ROWS       = 300000000
              %s},
            $DB->symquote($this->{sessiontable}, $this->{dbset}),
            $type_option));

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
            q{SELECT data, UNIX_TIMESTAMP(updatetime), checkval, checkvalssl
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

Tripletail::Session::MySQL - 内部用

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
