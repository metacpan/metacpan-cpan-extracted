package Tripletail::DB::Backend::Oracle::Dbh;
use strict;
use warnings;
use Tripletail;
our @ISA = qw(Tripletail::DB::Dbh);

sub connect {
    my $this = shift;

    $ENV{ORACLE_SID} = $TL->INI->get($this->{inigroup} => 'sid');
    $ENV{ORACLE_HOME} = $TL->INI->get($this->{inigroup} => 'home');
    $ENV{ORACLE_TERM} = 'vt100';
    $ENV{PATH} = $ENV{PATH} . ':' . $ENV{ORACLE_HOME} . '/bin';
    $ENV{LD_LIBRARY_PATH} = $ENV{LD_LIBRARY_PATH} . ':'
      . $ENV{ORACLE_HOME} . '/lib';
    $ENV{ORA_NLS33} = $ENV{ORACLE_HOME} . '/ocommon/nls/admin/data';
    $ENV{NLS_LANG} = 'JAPANESE_JAPAN.UTF8';

    my $user     = $TL->INI->get($this->{inigroup} => 'user');
    my $password = $TL->INI->get($this->{inigroup} => 'password');

    my $option = $user . '/' . $password;
    my $host   = $TL->INI->get($this->{inigroup} => 'host' => undef);
    if (defined($host)) {
        $option .= '@' . $host;
    }

    $this->{type} = 'oracle';
    $this->{dbh } = DBI->connect(
        'dbi:Oracle:',
        $option,
        '', {
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

    my $obj_sym  = $this->symquote($obj);
    my ($curval) = $this->{dbh}->selectrow_array(
                       qq{SELECT $obj_sym.curval FROM dual});
    return $curval;
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Backend::Oracle - 内部用

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
