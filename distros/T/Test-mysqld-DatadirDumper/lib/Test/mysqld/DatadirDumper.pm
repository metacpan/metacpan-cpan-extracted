package Test::mysqld::DatadirDumper;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Carp qw/croak/;
use DBI;
use DBIx::FixtureLoader;
use File::Spec;
use Test::mysqld;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/ddl_file datadir fixtures/],
);

sub dump {
    my $self = shift;

    my $datadir = $self->datadir;
    unless ( File::Spec->file_name_is_absolute($datadir) ) {
        $datadir = File::Spec->rel2abs($datadir),
    }

    my $mysqld = Test::mysqld->new(
        my_cnf   => {
            'skip-networking' => '',
            datadir => $datadir,
        },
    ) or die $Test::mysqld::errstr;

    my $dsn = $mysqld->dsn;
    my $dbh = DBI->connect($dsn, '', '', {
        RaiseError          => 1,
        PrintError          => 0,
        ShowErrorStatement  => 1,
        AutoInactiveDestroy => 1,
        mysql_enable_utf8   => 1,
    });

    my $source = do {
        local $/;
        open my $fh, '<', $self->ddl_file or die $!;
        <$fh>
    };
    my @statements = map { "$_;" } grep { /\S+/ } split ';', $source;
    for my $statement (@statements) {
        $dbh->do($statement) or croak $dbh->errstr;
    }

    if (my @fixtures = @{ $self->fixtures || [] }) {
        my $loader = DBIx::FixtureLoader->new(dbh => $dbh);
        $loader->load_fixture($_) for @fixtures;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::mysql::DatadirDumper - Dump mysql data directory for Test::mysqld

=head1 SYNOPSIS

    use Test::mysql::DatadirDumper;
    my $datadir = 'path/to/datadir';
    Test::mysqld::DatadirDumper->new(
        datadir  => $datadir,
        ddl_file => 't/data/ddl.sql',
        fixtures => ['t/data/item.yml'],
    )->dump;

    # $datadir is usable as follows
    my $mysqld = Test::mysqld->new(
        my_cnf => {
          'skip-networking' => '',
        },
        copy_data_from => $datadir,
    );

=head1 DESCRIPTION

Test::mysql::DatadirDumper is to dump data directory of mysql.
The directory is useful for L<Test::mysql>'s C<copy_data_from> option.

=head1 CONSTRUCTOR

C<new> is constructor and following options are available.

=over

=item C<datadir:Str>

Required. Data directory to be dumped.

=item C<ddl_file:Str>

Required. Create statements for mysql.

=item C<fixtures:ArrayRef>

Optional.

=back

=head1 METHOD

=head2 C<dump>

Dump data directory.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

