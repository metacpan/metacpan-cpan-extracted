package Tripletail::DB::Backend::Interbase::Dbh;
use strict;
use warnings;
use Tripletail;
our @ISA = qw(Tripletail::DB::Dbh);

sub connect {
    my $this = shift;

    my $opts = {
        dbname     => $TL->INI->get($this->{inigroup} => 'dbname'),
        ib_charset => 'UNICODE_FSS',
    };

    my $host = $TL->INI->get($this->{inigroup} => 'host' => undef);
    if (defined($host)) {
        $opts->{host} = $host;
    }

    my $port = $TL->INI->get($this->{inigroup} => 'port' => undef);
    if (defined($port)) {
        $opts->{port} = $port;
    }

    $this->{type} = 'interbase';
    $this->{dbh } = DBI->connect(
        'dbi:InterBase:' . join(';', map { "$_=$opts->{$_}" } keys %$opts),
        $TL->INI->get($this->{inigroup} => 'user' => undef),
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

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Backend::Interbase - 内部用

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
