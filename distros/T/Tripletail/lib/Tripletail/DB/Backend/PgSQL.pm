package Tripletail::DB::Backend::PgSQL::Dbh;
use strict;
use warnings;
use Hash::Util qw(lock_hash);
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
    if (defined($port) && $host ne '') {
        $opts->{port} = $port;
    }

    $this->{type} = 'pgsql';
    $this->{dbh } = DBI->connect(
        'dbi:Pg:' . join(';', map { "$_=$opts->{$_}" } keys %$opts),
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

    if (defined $obj) {
        my ($currval) = $this->{dbh}->selectrow_array(
                            'SELECT currval(?)', undef, $obj);
        return $currval;
    }
    else {
        my ($currval) = $this->{dbh}->selectrow_array(
                            'SELECT lastval()');
        return $currval;
    }
}

sub _mk_upsert_query {
    my $this   = shift;
    my $schema = shift;
    my $table  = shift;
    my $keys   = shift;
    my $values = shift;

    my $quoted_table
      = defined $schema ? $this->symquote($schema) . '.' . $this->symquote($table)
      :                   $this->symquote($table)
      ;

    my $update_statement = do {
        my $where_condition
          = join(
              ' AND ',
              map {
                  if (defined $keys->{$_}) {
                      sprintf('%s = %s', $this->symquote($_), $this->quote($keys->{$_}));
                  }
                  else {
                      sprintf('%s IS NULL', $this->symquote($_));
                  }
              } keys %$keys);

        if (keys %$values == 0) {
            # 主キー以外の値が一つも無いので UPDATE の代わりに SELECT
            # 文を用いて行の存在確認のみを行う。
            sprintf(
                q{PERFORM * FROM %s WHERE %s},
                $quoted_table,
                $where_condition
               );
        }
        else {
            my $set_pairs
              = join(
                  ', ',
                  map {
                      sprintf(
                          '%s = %s',
                          $this->symquote($_),
                          ( defined $values->{$_}
                              ? $this->quote($values->{$_})
                              : 'NULL' ))
                  } keys %$values);

            sprintf(
                q{UPDATE %s SET %s WHERE %s},
                $quoted_table,
                $set_pairs,
                $where_condition
               );
        }
    };

    my $insert_statement = do {
        my %merged = (%$keys, %$values);

        my $column_list
          = join(', ', map { $this->symquote($_) } keys %merged);

        my $value_list
          = join(', ', map { defined $merged{$_}
                               ? $this->quote($merged{$_}) : 'NULL' } keys %merged);

        sprintf(
            q{INSERT INTO %s (%s) VALUES (%s)},
            $quoted_table,
            $column_list,
            $value_list
           );
    };

    return sprintf(
        q{DO $$
                 BEGIN
                     LOOP
                         %s;
                         IF found THEN
                             RETURN;
                         END IF;

                         BEGIN
                            %s;
                            RETURN;
                         EXCEPTION WHEN unique_violation THEN
                         END;
                     END LOOP;
                 END;
             $$},
        $update_statement,
        $insert_statement
       );
}

my %ERROR_KEY_OF = (
    # http://www.postgresql.org/docs/9.1/interactive/errcodes-appendix.html
    '00000' => 'NO_ERROR',
    '40P01' => 'DEADLOCK_DETECTED'
   );
lock_hash %ERROR_KEY_OF;

sub _last_error_info {
    my $this = shift;
    my $dbh  = shift || $this->{dbh};

    return +{
        errno  => $dbh->err,
        errstr => $dbh->errstr,
        errkey => (exists $ERROR_KEY_OF{ $dbh->state }
                        ? $ERROR_KEY_OF{ $dbh->state }
                        : 'COMMON_ERROR')
       };
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Backend::PgSQL - 内部用

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
