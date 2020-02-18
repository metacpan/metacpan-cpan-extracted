package Weather::MOSMIX::Writer;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
require POSIX;
use JSON;

=head1 NAME

Weather::MOSMIX::Writer - Write MOSMIX weather forecast data to a DBI handle

=head1 SYNOPSIS

    my $w = Weather::MOSMIX::Writer->new(
        dbh => {
            dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
        },
    );
    my $r = Weather::MOSMIX::Reader->new(
        writer => $w,
    );

    for my $file (@files) {
        status("Importing $file\n");
        $r->read_zip( $file );
    };

=cut

our $VERSION = '0.02';

# This should be MooX::Role::DBConnection
with 'MooX::Role::DBIConnection';

has 'insert_location_sth' => (
    is => 'lazy',
    default => \&_prepare_location_sth,
);

has 'insert_forecast_sth' => (
    is => 'lazy',
    default => \&_prepare_forecast_sth,
);

has 'json' => (
    is => 'lazy',
    default => sub {
        JSON->new()
    },
);

sub _prepare_location_sth( $self ) {
    $self->dbh->prepare(<<'SQL');
        insert or replace into forecast_location (
            name, description, latitude, longitude, elevation
        ) values (
            ?,    ?,           ?,        ?,         ?
        )
SQL
}

sub _prepare_forecast_sth( $self ) {
    $self->dbh->prepare(<<'SQL');
        insert into forecast (
            name, forecasts, expiry, issuetime
        ) values (
            ?,    ?,        ?,       ?
        )
SQL
}

sub purge_expired_records( $self, $date = POSIX::strftime('%Y-%m-%d %H:%M:%SZ', gmtime()) ) {
    $self->dbh->do(<<'SQL', $date);
        delete from forecast
            where expiry <= ?
SQL
}

sub purge_outdated_expired_records( $self ) {
    $self->dbh->do(<<'SQL');
        delete from forecast
            where expiry < (select max(expiry) from forecast)
SQL
}

sub start( $self ) {
    my $dbh = $self->dbh;
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 0;
    $dbh->do('PRAGMA synchronous = OFF');
    $dbh->do('PRAGMA journal_mode = MEMORY');
    $dbh->{AutoCommit} = 0;
};

sub insert( $self, $expiry, @records ) {
    my $i = 0;
    $self->insert_location_sth->execute_for_fetch(sub {
        my $rec = $records[$i++];
        return if ! $rec;
        [@{$rec}{qw(name description latitude longitude elevation)}]
    });
    $i = 0;
    $self->insert_forecast_sth->execute_for_fetch(sub {
        my $rec = $records[$i++];
        return if ! $rec;
        my $f = $self->json->encode( $rec->{forecasts} );
        [$rec->{name}, $f, $expiry, $rec->{issuetime}]
    });
};

sub commit( $self ) {
    $self->dbh->commit;
}

=head2 C<< Weather::MOSMIX::Writer->create_db >>

    $w->create_db(
        dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
    );

Shorthand to create the database file. If no dbh is already set, this sets
the active database handle.

=cut

sub create_db( $self, %options ) {
    require DBIx::RunSQL;
    require File::ShareDir;
    my $dbh = DBIx::RunSQL->run(
        sql => File::ShareDir::dist_file('Weather-MOSMIX', 'create.sql'),
        %options,
    );
    if( ref $self ) {
        $self->{dbh} = $dbh      # our dbh is generally read-only
            unless $self->{dbh}; # we look directly so the lazy builder doesn't kick in
    };
    return $dbh
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/weather-mosmix>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-MOSMIX>
or via mail to L<www-Weather-MOSMIX@rt.cpan.org|mailto:Weather-MOSMIX@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019-2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
