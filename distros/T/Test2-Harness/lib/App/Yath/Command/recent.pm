package App::Yath::Command::recent;
use strict;
use warnings;

our $VERSION = '2.000005';

use Term::Table;
use Test2::Harness::Util::JSON qw/decode_json/;
use App::Yath::Schema::Util qw/schema_config_from_settings/;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

use Getopt::Yath;

include_options(
    'App::Yath::Options::Yath',
    'App::Yath::Options::Recent',
    'App::Yath::Options::WebClient',
    'App::Yath::Options::DB',
);

sub summary { "Show a list of recent runs (using logs, database and/or web server)" }

sub group { 'history' }

sub cli_args { "" }

sub description {
    return <<"    EOT";
This command will find the last several runs from a yath server
    EOT
}

sub run {
    my $self = shift;

    my $settings = $self->settings;

    my $yath   = $settings->yath;
    my $recent = $settings->recent;

    my ($is_term, $use_color) = (0, 0);
    if (-t STDOUT) {
        require Term::Table::Cell;
        $is_term   = 1;
        $use_color = eval { require Term::ANSIColor; 1 };
    }

    my $project = $yath->project // die "--project is a required argument.\n";
    my $count   = $recent->max || 10;
    my $user    = $settings->yath->user;

    my $data = $self->get_data($project, $count, $user) or die "Could not get any data.\n";

    @$data = reverse @$data;

    my $url = $settings->server->url;
    $url =~ s{/$}{}g if $url;

    my $header = [qw/Time Duration Status Pass Fail Retry/, "Run ID"];
    push @$header => 'Link' if $url;

    my $rows = [];
    for my $run (@$data) {
        push @$rows => [@{$run}{qw/added duration status passed failed retried run_id/}];

        if ($url) {
            push @{$rows->[-1]} => $run->{status} ne 'broken' ? "$url/view/$run->{run_id}" : "N/A";
        }

        my $color;
        if    ($run->{status} eq 'broken')   { $color = "magenta" }
        elsif ($run->{status} eq 'pending')  { $color = "blue" }
        elsif ($run->{status} eq 'running')  { $color = "blue" }
        elsif ($run->{status} eq 'canceled') { $color = "yellow" }
        elsif ($run->{failed})               { $color = "bold red" }
        elsif ($run->{retried})              { $color = "bold cyan" }
        elsif ($run->{passed})               { $color = "bold green" }

        if ($use_color && $color) {
            $_ = Term::Table::Cell->new(value => $_, value_color => Term::ANSIColor::color($color), reset_color => Term::ANSIColor::color("reset"))
                for @{$rows->[-1]};
        }
    }

    my $table = Term::Table->new(
        header => $header,
        rows => $rows,
    );

    print "$_\n" for $table->render;

    return 0;
}

sub get_data {
    my $self = shift;
    my ($project, $count, $user) = @_;

    return $self->get_from_db($project, $count, $user)
        || $self->get_from_http($project, $count, $user);
}

sub get_from_db {
    my $self = shift;
    my ($project, $count, $user) = @_;

    my $settings = $self->settings;
    my $config = schema_config_from_settings($settings) or return undef;
    my $schema = $config->schema or return undef;

    my $runs = $schema->vague_run_search(
        username     => $user,
        project_name => $project,
        query        => {},
        attrs        => {order_by => {'-desc' => 'added'}, rows => $count},
        list         => 1,
    );

    my $data = [];

    while (my $run = $runs->next) {
        push @$data => $run->TO_JSON;
    }

    return undef unless @$data;

    return $data;
}

sub get_from_http {
    my $self = shift;
    my ($project, $count, $user) = @_;

    my $settings = $self->settings;
    my $server = $settings->server;

    require HTTP::Tiny;
    my $ht  = HTTP::Tiny->new();
    my $url = $server->url or return;
    $url =~ s{/$}{}g;
    $url .= "/recent/$project/$user";
    my $res = $ht->get($url);

    die "Could not get recent runs from '$url'\n$res->{status}: $res->{reason}\n$res->{content}\n"
        unless $res->{success};

    return decode_json($res->{content});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::recent - Show a list of recent runs (using logs, database and/or web server)

=head1 DESCRIPTION

This command will find the last several runs from a yath server


=head1 USAGE

    $ yath [YATH OPTIONS] recent [COMMAND OPTIONS]

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

=head3 Harness Options

=over 4

=item -d

=item --dummy

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>

The following environment variables will be cleared after arguments are processed: C<T2_HARNESS_DUMMY>


=item --procname-prefix ARG

=item --procname-prefix=ARG

=item --no-procname-prefix

Add a prefix to all proc names (as seen by ps).

The following environment variables will be set after arguments are processed: C<T2_HARNESS_PROC_PREFIX>


=back

=head3 Recent Options

=over 4

=item --recent-max 10

=item --no-recent-max

Max number of recent runs to show


=back

=head3 Web Client Options

=over 4

=item --api-key ARG

=item --api-key=ARG

=item --no-api-key

Yath server API key. This is not necessary if your Yath server instance is set to single-user

Can also be set with the following environment variables: C<YATH_API_KEY>


=item --grace

=item --no-grace

If yath cannot connect to a server it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.


=item --request-retry

=item --request-retry=COUNT

=item --no-request-retry

How many times to try an operation before giving up

Note: Can be specified multiple times, counter bumps each time it is used.


=item --url http://my-yath-server.com/...

=item --uri http://my-yath-server.com/...

=item --no-url

Yath server url

Can also be set with the following environment variables: C<YATH_URL>


=back

=head3 Yath Options

=over 4

=item --base-dir ARG

=item --base-dir=ARG

=item --no-base-dir

Root directory for the project being tested (usually where .yath.rc lives)


=item -D

=item -Dlib

=item -Dlib

=item -D=lib

=item -D"lib/*"

=item --dev-lib

=item --dev-lib=lib

=item --dev-lib="lib/*"

=item --no-dev-lib

This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Note: This option can cause yath to use exec() to reload itself with the correct libraries in place. Each occurence of this argument can cause an additional exec() call. Use --dev-libs-verbose BEFORE any -D calls to see the exec() calls.

Note: Can be specified multiple times


=item --dev-libs-verbose

=item --no-dev-libs-verbose

Be verbose and announce that yath will re-exec in order to have the correct includes (normally yath will just call exec() quietly)


=item -h

=item -h=Group

=item --help

=item --help=Group

=item --no-help

exit after showing help information


=item -p key=val

=item -p=key=val

=item -pkey=value

=item -p '{"json":"hash"}'

=item -p='{"json":"hash"}'

=item -p:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin key=val

=item --plugin=key=val

=item --plugins key=val

=item --plugins=key=val

=item --plugin '{"json":"hash"}'

=item --plugin='{"json":"hash"}'

=item --plugins '{"json":"hash"}'

=item --plugins='{"json":"hash"}'

=item --plugin :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-plugins

Load a yath plugin.

Note: Can be specified multiple times


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file.


=item --scan-options key=val

=item --scan-options=key=val

=item --scan-options '{"json":"hash"}'

=item --scan-options='{"json":"hash"}'

=item --scan-options(?^:^--(no-)?(?^:scan-(.+))$)

=item --scan-options :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --scan-options=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-scan-options

=item /^--(no-)?scan-(.+)$/

Yath will normally scan plugins for options. Some commands scan other libraries (finders, resources, renderers, etc) for options. You can use this to disable all scanning, or selectively disable/enable some scanning.

Note: This is parsed early in the argument processing sequence, before options that may be earlier in your argument list.

Note: Can be specified multiple times


=item --show-opts

=item --show-opts=group

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --user ARG

=item --user=ARG

=item --no-user

Username to associate with logs, database entries, and yath servers.

Can also be set with the following environment variables: C<YATH_USER>, C<USER>


=item -V

=item --version

=item --no-version

Exit after showing a helpful usage message


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

