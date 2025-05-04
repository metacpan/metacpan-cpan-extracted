package App::Yath::Command::db::publish;
use strict;
use warnings;

our $VERSION = '2.000005';

use Time::HiRes qw/time/;

use IO::Uncompress::Bunzip2 qw($Bunzip2Error);
use IO::Uncompress::Gunzip  qw($GunzipError);

use App::Yath::Schema::Util qw/schema_config_from_settings format_duration/;
use Test2::Harness::Util::JSON qw/decode_json/;

use App::Yath::Schema::RunProcessor;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

use Getopt::Yath;
include_options(
    'App::Yath::Options::DB',
    'App::Yath::Options::Publish',
);

sub summary     { "Publish a log file directly to a yath database" }
sub group       { ["database", 'log parsing'] }
sub cli_args    { "[--] event_log.jsonl[.gz|.bz2]" }
sub description { "Publish a log file directly to a yath database" }

sub run {
    my $self = shift;

    my $args = $self->args;
    my $settings = $self->settings;

    shift @$args if @$args && $args->[0] eq '--';

    my $file = shift @$args or die "You must specify a log file";
    die "'$file' is not a valid log file" unless -f $file;
    die "'$file' does not look like a log file" unless $file =~ m/\.jsonl(\.(gz|bz2))?$/;

    my $lines = 0;
    my $fh;
    if ($file =~ m/\.bz2$/) {
        $fh = IO::Uncompress::Bunzip2->new($file) or die "Could not open bz2 file: $Bunzip2Error";
        $lines++ while <$fh>;
        $fh = IO::Uncompress::Bunzip2->new($file) or die "Could not open bz2 file: $Bunzip2Error";
    }
    elsif ($file =~ m/\.gz$/) {
        $fh = IO::Uncompress::Gunzip->new($file) or die "Could not open gz file: $GunzipError";
        $lines++ while <$fh>;
        $fh = IO::Uncompress::Gunzip->new($file) or die "Could not open gz file: $GunzipError";
    }
    else {
        open($fh, '<', $file) or die "Could not open log file: $!";
        $lines++ while <$fh>;
        seek($fh, 0, 0);
    }

    my $user = $settings->yath->user;

    my $is_term = -t STDOUT ? 1 : 0;

    print "\n" if $is_term;

    my $project = $file;
    $project =~ s{^.*/}{}g;
    $project =~ s{\.jsonl.*$}{}g;
    $project =~ s/-\d.*$//g;
    $project =~ s/^\s+//g;
    $project =~ s/\s+$//g;

    my $start = time;

    my $cb = App::Yath::Schema::RunProcessor->process_lines($settings, project => $project, print_links => 1);

    my $run;
    eval {
        my $ln = <$fh>;
        $run = $cb->($ln);
        1
    } or return $self->fail($@);

    $SIG{INT} = sub {
        print STDERR "\nCought SIGINT...\n";
        eval { $run->update({status => 'canceled', error => "SIGINT while importing"}); 1 } or warn $@;
        exit 255;
    };

    $SIG{TERM} = sub {
        print STDERR "\nCought SIGTERM...\n";
        eval { $run->update({status => 'canceled', error => "SIGTERM while importing"}); 1 } or warn $@;
        exit 255;
    };

    my $len = length("" . $lines);

    local $| = 1;
    while (my $line = <$fh>) {
        my $ln = $.;

        printf("\033[Fprocessing '%s' line: % ${len}d / %d\n", $file, $ln, $lines)
            if $is_term;

        next if $line =~ m/^null$/ims;

        eval { $cb->($line); 1 } or return $self->fail($@, $run);
    }

    $cb->();

    my $end = time;

    my $dur = format_duration($end - $start);

    print "Published Run. [Status: " . $run->status . ", Duration: $dur]\n";

    return 0;
}

sub fail {
    print STDERR "FAIL!\n\n";
    my $self = shift;
    my ($err, $run) = @_;

    $run->update({status => 'broken', error => $err}) if $run;

    print STDERR "\n$err\n";

    print STDERR "\nPublish Failed.\n";
    return 255;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::db::publish - Publish a log file directly to a yath database

=head1 DESCRIPTION

Publish a log file directly to a yath database

=head1 USAGE

    $ yath [YATH OPTIONS] db-publish [COMMAND OPTIONS] [COMMAND ARGUMENTS]

=head2 OPTIONS

=head3 Database Options

=over 4

=item --db-config ARG

=item --db-config=ARG

=item --no-db-config

Module that implements 'MODULE->yath_db_config(%params)' which should return a App::Yath::Schema::Config instance.

Can also be set with the following environment variables: C<YATH_DB_CONFIG>


=item --db-driver Pg

=item --db-driver MySQL

=item --db-driver SQLite

=item --db-driver MariaDB

=item --db-driver Percona

=item --db-driver PostgreSQL

=item --no-db-driver

DBI Driver to use

Can also be set with the following environment variables: C<YATH_DB_DRIVER>


=item --db-dsn ARG

=item --db-dsn=ARG

=item --no-db-dsn

DSN to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_DSN>


=item --db-host ARG

=item --db-host=ARG

=item --no-db-host

hostname to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_HOST>


=item --db-name ARG

=item --db-name=ARG

=item --no-db-name

Name of the database to use

Can also be set with the following environment variables: C<YATH_DB_NAME>


=item --db-pass ARG

=item --db-pass=ARG

=item --no-db-pass

Password to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PASS>


=item --db-port ARG

=item --db-port=ARG

=item --no-db-port

port to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_PORT>


=item --db-socket ARG

=item --db-socket=ARG

=item --no-db-socket

socket to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_SOCKET>


=item --db-user ARG

=item --db-user=ARG

=item --no-db-user

Username to use when connecting to the db

Can also be set with the following environment variables: C<YATH_DB_USER>, C<USER>


=back

=head3 Publish Options

=over 4

=item --publish-buffer-size 100

=item --no-publish-buffer-size

Maximum number of events, coverage, or reporting items to buffer before flushing them (each has its own buffer of this size, and each job has its own event buffer of this size)


=item --publish-flush-interval 2

=item --publish-flush-interval 1.5

=item --no-publish-flush-interval

When buffering DB writes, force a flush when an event is recieved at least N seconds after the last flush.


=item --publish-force

=item --no-publish-force

If the run has already been published, override it. (Delete it, and publish again)


=item --publish-mode qvf

=item --publish-mode qvfd

=item --publish-mode summary

=item --publish-mode complete

=item --no-publish-mode

Set the upload mode (default 'qvfd')


=item --publish-retry

=item --publish-retry=COUNT

=item --no-publish-retry

How many times to retry an operation before giving up

Note: Can be specified multiple times, counter bumps each time it is used.


=item --publish-user ARG

=item --publish-user=ARG

=item --no-publish-user

User to publish results as


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

