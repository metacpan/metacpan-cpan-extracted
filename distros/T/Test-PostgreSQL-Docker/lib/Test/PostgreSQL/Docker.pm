package Test::PostgreSQL::Docker;
use 5.014;
use strict;
use warnings;
use DBI;
use DBD::Pg;
use Sub::Retry qw/retry/;
use Net::EmptyPort qw/empty_port/;
use IPC::Run ();

our $VERSION = "0.03001";
our $DEBUG;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        docker  => undef,
        pgname  => "postgres",
        tag     => 'latest',
        port    => empty_port(),
        host    => "127.0.0.1",
        dbowner => "postgres",
        password=> "postgres",
        dbname  => "test",
        print_docker_error => 1,
        _orig_address => '',
        %opts,
    }, $class;
    $self->{docker} = $self->_search_docker_path() unless $self->docker;
    $self->oid;
    return $self;
}

sub _search_docker_path {
    my $self = shift;
    my @paths = qw( /usr/bin /usr/local/bin );
    my $decided;
    for my $path ( @paths ) {
        if ( -x "$path/docker" ) {
            $decided = "$path/docker";
            last;
        }
    }
    return $decided;
}

sub _address {
    my $self = shift;
    ("$self" =~ /HASH\(0x([0-9a-f]+)\)/)[0];
}

sub oid {
    my ( $self ) = @_;
    return $self->{oid} if defined $self->{oid};
    $self->{oid} = $self->_address;
}

sub pull {
    my ($self) = @_;
    my $image = $self->image_name();
    $self->docker_cmd(pull => ['--quiet', $image]);
    $self;
}

sub run {
    my ($self, %opt) = @_;

    return $self unless $self->docker_daemon_is_accessible;
    return $self if $self->docker_is_running;

    $self->pull() unless (exists $opt{skip_pull} ? $opt{skip_pull} : 1);

    my $image = $self->image_name();
    my $ctname = $self->container_name();
    my $class  = ref($self);

    my $host = $self->{host};
    my $user = $self->{dbowner};
    my $pass = $self->{password};
    my $port = $self->{port};
    my $dbname = $self->{dbname};
    my @envs   = map { ('-e', $_) } "POSTGRES_USER=$user", "POSTGRES_PASSWORD=$pass", "POSTGRES_DB=$dbname";
    my ( $out, $err ) = $self->docker_cmd(run => ['--rm', '--name', $ctname, '-p', "$host:$port:5432", @envs, '-d', "$image"]);

    if ( !$err or $err =~ /Status: Downloaded newer image for/) { # for auto pulling
        $self->{docker_is_running} = 1;
        $self->{_orig_address} = $self->_address;
        $self->dbh unless $opt{skip_connect};
    }

    $self;
}

sub DESTROY {
    my ( $self ) = @_;
    $self->{dbh}->disconnect() if defined $self->{dbh};
    return if $self->_address ne $self->{_orig_address};
    $self->docker_cmd(kill => [$self->container_name]) if $self->docker_is_running;
}

sub docker {
    shift->{docker};
}

sub docker_is_running {
    shift->{docker_is_running};
}

sub docker_daemon_is_accessible {
    my ( $self ) = @_;
    return unless -x $self->docker;
    my ( $out, $err ) = $self->docker_cmd('ps');
    $err ? 0 : 1;
}

sub docker_cmd {
    my ( $self, $action, $args, $io ) = @_;
    $args //= [];
    my @cmds = ($self->docker, $action, @$args);
    $DEBUG && print STDERR join(' ', @cmds),"\n";

    my ( $in, $out, $err );
    if ( $io ) {
        IPC::Run::run( \@cmds, '<', ($io->{in} ? $io->{in} : \$in), '>', ($io->{out} ? $io->{out} : \$out), '2>', ($io->{err} ? $io->{err} : \$err) );
    }
    else {
        IPC::Run::run \@cmds, \$in, \$out, \$err;
    }

    $self->{print_docker_error} && $err && print STDERR $err, "\n";

    return ($out, $err);
}

sub psql_args {
    my $self = shift;
    if ( @_ ) {
        $self->{psql_args} = $_[0];
    }
    $self->{psql_args}
        ||= ['-h', $self->{host}, '-p', 5432, '-U', $self->{dbowner}, '-d',  $self->{dbname}];
}

sub run_psql {
    my ($self, @args) = @_;
    my %io;
    if ( ref($args[-1]) eq 'HASH' ) {
        %io = %{ (pop @args) };
    }
    $self->dbh(); ## waiting for DB connection
    $self->docker_cmd( exec => ['-i', $self->container_name, 'psql', @{$self->psql_args}, @args], \%io );
}

sub run_psql_scripts {
    my ($self, @scripts) = @_;
    for my $script ( @scripts ) {
        $self->run_psql({ in => $script });
    }
    $self;
}

sub dsn {
    my ($self, %args) = @_;
    $args{port}     ||= $self->{port};
    $args{host}     ||= $self->{host};
    $args{user}     ||= $self->{dbowner};
    $args{dbname}   ||= $self->{dbname};
    $args{password} ||= $self->{password};
    return 'DBI:Pg:' . join(';', map { "$_=$args{$_}" } sort keys %args);
}

sub dbh {
    my ($self, $option) = @_;
    return $self->{dbh} if $self->{dbh};

    $option ||= {AutoCommit => 0, RaiseError => 1, PrintError => 0};
    $self->{dbh} = retry 5, 2, sub {
        DBI->connect($self->dsn, '', '', $option);
    };
    $self->{dbh};
}

sub port {
    shift->{port};
}

sub container_name {
    my ($self) = @_;
    my $pgname = $self->{pgname};
    $pgname =~ s/[^a-zA-Z0-9_.-]/__/g;
    sprintf "%s-%s-%s", $pgname, $self->{tag}, $self->oid;
}

sub image_name {
    my ($self) = @_;
    sprintf "%s:%s", $self->{pgname}, $self->{tag};
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::PostgreSQL::Docker - A Postgresql mock server for testing perl programs

=head1 SYNOPSIS

    use Test::More;
    use Test::PostgreSQL::Docker;
    
    # 1. create a instance of Test::PostgreSQL::Docker with postgres:12-alpine image
    my $server = Test::PostgreSQL::Docker->new(tag => '12-alpine');
    
    # 2. create/run a container
    $server->run();
    
    # 3. puke initialization data into postgresql on a container
    $server->run_psql_scripts("/path/to/fixture.sql");
    
    # 4. get a Database Handler(a DBI::db object) from mock server object
    my $dbh = $server->dbh();
    
    # (or call steps of 2 to 4 as method-chain)
    my $dbh = $server->run->run_psql_scripts("/path/to/fixture.sql")->dbh;
    
    # 5. query to database
    my $sth = $dbh->prepare("SELECT * FROM Users WHERE id=?");
    $sth->execute(1);
    
    # 6. put your own test code below
    my $row $sth->fetchrow_hashref();
    is $row->{name}, "ytnobody";
    
    done_testing;

=head1 DESCRIPTION

Test::PostgreSQL::Docker run the postgres container on the Docker, for testing your perl programs.

B<**NOTE**> Maybe this module doesn't work on the Windows, because we don't any test on Windows machine.


=head1 METHODS

=head2 new

    $server = Test::PostgreSQL::Docker->new(%opt)

=over 2

=item docker (str)

The path to C<docker>. Default is C</usr/bin/docker>.

=item pgname (str)

A distribution name. Default is C<postgres>.

=item tag (str)

A tag of the PostgreSQL. Default is C<latest>. 

=item oid (str)

An uniqe id. Default is the object memory addres.

=item dbowner (str)

Default is C<postgres>.

=item password (str)

Default is C<postgres>.

=item dbname (str)

Default is C<test>.

=item print_docker_error (bool)

Show docker error. Default is C<true value>.

=back

=head2 run

    $server = $server->run(%opt)

1. Check image with C<docker pull>.

2. C<docker run>

3. C<connect database>

=over 2

=item skip_pull (bool)

Skip image check. Default is C<true>.

=item skip_connect (bool)

Skip connect database. Default is C<false>.

=back

=head2 oid

    $oid = $server->oid()

Return an unique id.


=head2 container_name

    $container_name = $server->container_name()

Return the docker container name C<sprintf('%s-%s-%s', $pgname, $tag, $oid)>.


=head2 image_name

    $image_name = $server->image_name()

Return the docker image name.


=head2 dsn

    $dsn = $server->dsn(%opt)

=head2 port

    $port = $server->port()

Return a PostgreSQL server port.

=head2 dbh

    $dbh = $server->dbh()

=head2 psql_args

    $psql_args = $server->psql_args()
    $psql_args = $server->psql_args($args)

Arguments to C<psql> in C<run_psql> and C<run_psql_scripts>.
Default is C<sprintf('-h %s -p %s -U %s -d %s', $self->{host}, 5432, $self->{dbowner}, $self->{dbname})>.


=head2 run_psql

    $server = $server->run_psql(@args)

    $server->run_psql('-c', q|INSERT INTO foo (bar) VALUES ('baz')|);


=head2 run_psql_scripts

    $server = $server->run_psql_scripts($path)


=head2 docker_is_running

    $server = $server->docker_is_running()

Return true if docker container is running.


=head2 docker_daemon_is_accessible

    $server = $server->docker_daemon_is_accessible()

Return true if docker daemon is accessible.


=head1 REQUIREMENT

=over 2

=item Docker

This module uses the Docker as ephemeral environment.

=back

=head1 LICENSE

Copyright (C) Satoshi Azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Satoshi Azuma E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<Test::PostgreSQL>
L<https://hub.docker.com/_/postgres>

=cut

