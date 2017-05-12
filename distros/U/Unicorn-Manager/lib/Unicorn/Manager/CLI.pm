package Unicorn::Manager::CLI;

use 5.010;
use strict;
use warnings;
use autodie;
use Moo;
use Carp;              # for sane error reporting
use File::Basename;    # to strip the config file from the path
use File::Find;
use Cwd 'abs_path';

use Unicorn::Manager::CLI::Proc;
use Unicorn::Manager::Version;

has username => ( is => 'rw', required => 1 );
has group    => ( is => 'rw' );
has config   => ( is => 'rw' );
has DEBUG    => ( is => 'rw' );
has proc     => ( is => 'rw' );
has uid      => ( is => 'rw' );
has rails    => ( is => 'rw' );
has version  => (
    is      => 'ro',
    default => sub {
        Unicorn::Manager::Version->new;
    },
);

sub start {
    my ( $self, $opts ) = @_;
    my $config_file = $opts->{config};
    my $args        = $opts->{args};
    my $timeout     = 20;
    if ( -f $config_file ) {
        if ( my $pid = fork() ) {
            my $spawned = 0;
            while ( $spawned == 0 && $timeout > 0 ) {
                sleep 2;
                $self->proc->refresh;
                $spawned = 1 if $self->proc->process_table->ptable->{ $self->uid };
                $timeout--;
            }
            croak "Failed to start unicorn. Timed out.\n" if $timeout <= 0;

        }
        else {

            # 0 => name
            # 2 => uid
            # 3 => gid
            # 7 => home dir
            my @passwd = getpwnam( $self->username );

            # drop rights:
            # group rights first because we can not drop group rights
            # after user rights
            # set $HOME to our users home directory
            $ENV{'HOME'} = $passwd[7];
            $( = $) = $passwd[3];
            $< = $> = $passwd[2];

            my $appdir = '';
            my $conf_file;
            my $conf_dir;

            if ( defined $config_file && $config_file ne '' ) {
                $conf_dir  = dirname($config_file);
                $conf_file = basename($config_file);

                if ( $self->_is_abspath($conf_dir) ) {
                    $appdir = $conf_dir;
                }
                else {
                    $appdir = abs_path($conf_dir);
                }
            }

            $self->_change_dir($appdir);

            my $argstring;

            $argstring .= $_ . ' ' for @{$args};

            $ENV{'RAILS_ENV'} = 'development' unless $ENV{'RAILS_ENV'};

            # spawn the unicorn
            if ( $self->rails ) {

                # start unicorn_rails
                exec "/bin/bash --login -c \"unicorn_rails -c $conf_file $argstring\"";
            }
            else {

                # start unicorn
                exec "/bin/bash --login -c \"unicorn -c $conf_file $argstring\"";
            }
        }
    }
    else {
        return 0;
    }
    return 1;
}

sub query {

    # TODO
    # Put all of this into Unicorn::Manager::CLI::Query or similar
    my ( $self, $query, @params ) = @_;
    my $render = sub {
        my $status  = shift;
        my $message = shift;
        my $data    = shift;

        my $json = JSON->new->utf8(1);

        return $json->encode(
            {
                status  => $status,
                message => $message || undef,
                data    => $data || undef,
            }
        );
    };

    my $dispatch_table = {
        has_unicorn => sub {
            my $user = shift @params;
            return $render->( 0, 'no user defined' ) unless $user;
            return $render->( 1, 'user has unicorn' );
        },
        running => sub {

            # refresh before querying
            $self->proc->refresh;

            # TODO
            # fix the encode->decode->encode
            return $render->( 1, 'running unicorns', JSON::decode_json( $self->proc->as_json ) );
        },
        help => sub {
            my $help = {
                has_unicorn => {
                    description => 'return true or false',
                    params      => ['username'],
                },
                running => {
                    description => 'return unicorn masters and children running for all users',
                    params      => [],
                },
            };
            return $render->( 1, 'uc.pl query options', $help );
        },
    };

    if ( exists $dispatch_table->{$query} ) {
        $dispatch_table->{$query}->(@params);
    }
    else {
        $dispatch_table->{help}->();
    }

}

sub stop {
    my $self   = shift;
    my $master = ( keys %{ $self->proc->process_table->ptable->{ $self->uid } } )[0];

    $self->_send_signal( 'QUIT', $master ) if $master;

    return 1;
}

sub restart {
    my ( $self, $opts ) = @_;
    my $mode = $opts->{mode} || 'graceful';

    my @signals = ( 'USR2', 'WINCH', 'QUIT' );
    my $master = ( keys %{ $self->proc->process_table->ptable->{ $self->uid } } )[0];

    my $err = 0;

    for (@signals) {
        $err += $self->_send_signal( $_, $master );
        sleep 5;
    }

    if ( ( defined $mode && $mode eq 'hard' ) || $err ) {
        $err = 0;
        $err += $self->stop;
        sleep 3;
        $err += $self->start;
    }

    if ($err) {
        carp "error restarting unicorn! error code: $err\n";
        return 0;
    }
    else {
        return 1;
    }
}

sub reload {
    my $self = shift;
    my $err;

    for my $pid ( keys %{ $self->proc->process_table->ptable->{ $self->uid } } ) {
        $err = $self->_send_signal( 'HUP', $pid );
    }

    $err > 0 ? return 0 : return 1;
}

sub read_config {
    my $self     = shift;
    my $filename = shift;

    # TODO
    # should return a config object
    #
    # all config related stuff should go into a seperate class anyway: Unicorn::Manager::CLI::Config
    return 0;
}

sub write_config {
    my $self     = shift;
    my $filename = shift;

    # TODO
    # this one wont be fun ..
    # create a unicorn.conf from config hash
    # this is basically ruby code, so an idea could be to build it from
    # heredoc snippets
    #
    # should return a string. could be written to file or screen.
    #
    # all config related stuff should go into a seperate class anyway: Unicorn::Manager::CLI::Config
    return 0;
}

sub add_worker {
    my ( $self, $opts ) = @_;
    my $num = $opts->{num} || 1;

    # return error on non positive number
    return 0 unless $num > 0;

    my $err = 0;

    for ( 1 .. $num ) {
        my $master = ( keys %{ $self->proc->process_table->ptable->{ $self->uid } } )[0];

        $err += $self->_send_signal( 'TTIN', $master );
    }

    $err > 0 ? return 0 : return 1;
}

sub remove_worker {
    my ( $self, $opts ) = @_;
    my $num = $opts->{num} || 1;

    # return error on non positive number
    return 0 unless $num > 0;

    my $err    = 0;
    my $master = ( keys %{ $self->proc->process_table->ptable->{ $self->uid } } )[0];
    my $count  = @{ $self->proc->process_table->ptable->{ $self->uid }->{$master} };

    # save at least one worker
    $num = $count - 1 if $num >= $count;

    if ( $self->DEBUG ) {
        print "\$count => $count\n";
        print "\$num   => $num\n";
    }

    for ( 1 .. $num ) {
        $err += $self->_send_signal( 'TTOU', $master );
    }

    $err > 0 ? return 0 : return 1;
}

#
# send a signal to a pid
#
sub _send_signal {
    my ( $self, $signal, $pid ) = @_;
    ( kill $signal => $pid ) ? return 0 : return 1;
}

#
# small piece to check if a path is starting at root
#
sub _is_abspath {
    my ( $self, $path ) = @_;
    return 0 unless $path =~ /^\//;
    return 1;
}

#
# cd into the given dir
# requires an absolute path
#
sub _change_dir {
    my ( $self, $dir ) = @_;

    # requires abs path
    return 0 unless $self->_is_abspath($dir);

    my $dh;

    opendir $dh, $dir;
    chdir $dh;
    closedir $dh;

    use Cwd;

    cwd() eq $dir ? return 1 : return 0;
}

sub BUILD {
    my $self = shift;

    # does username exist?
    if ( $self->DEBUG ) {
        print "Initializing object with username: " . $self->username . "\n";
    }
    croak "no such username\n" unless getpwnam( $self->username );

    $self->uid( ( getpwnam( $self->username ) )[2] );
    $self->proc( Unicorn::Manager::CLI::Proc->new ) unless $self->proc;

}

1;

__END__

=head1 NAME

Unicorn::Manager::CLI - A Perl interface to the Unicorn webserver

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.006009

=head1 SYNOPSIS

The Unicorn::Manager::CLI module aimes to provide methods to start, stop and
gracefully restart the server. You can add and remove workers on the fly.

TODO:
Unicorn::Manager::CLI::Config should provide methods to create config files and
offer an OO interface to the config object.

Until now basically only unicorn_rails is supported. This Lib is a quick hack
to integrate management of rails apps with rvm and unicorn into perl scripts.

Also some assumption are made about your environment:
    you use Linux (the module relies on /proc)
    you use the bash shell
    your unicorn config is located in your apps root directory
    every user is running one single application

I will add and improve what is needed though. Requests and patches are
welcome.

=head1 ATTRIBUTES/CONSTRUCTION

Unicorn::Manager::CLI has following attributes:

=head2 username

Username of the user that owns the Unicorn process that will be operated
on.

The username is a required attribute.

=head2 group

Groupname of the Unicorn process. Defaults to the users primary group.

=head2 config

A HashRef containing the information to create a Unicorn::Config object.
See perldoc Unicon::Config for more information.

=head2 proc

A Unicorn::Manager::CLI::Proc object. If omitted it will be created automatically.

=head2 uid

The user id matching the given username. Will be set automatically on object creation.

=head2 rails

Currently unused flag.

=head2 version

Get the Unicorn::Manager::CLI version.

=head2 DEBUG

Is a Bool type attribute. Defaults to 'false' and prints additional
information if set 'true'.

TODO: Needs to be improved.

=head2 Contruction

    my $unicorn = Unicorn::Manager::CLI->new(
        username => 'myuser',
        group    => 'mygroup',
    );

=head1 METHODS

=head2 start

    $unicorn->start({
        config => '/path/to/my/config',
        args => ['-D', '--host 127.0.0.1'],
    });

Parameters are the path to the config file and an optional ArrayRef with
additional arguments.
These will override the arguments defined in the config file.

This method needs more love and will be rethought and rewritten. Now it
assumes the config file is located in the rails apps root directory. It
changes into this directory and drops rights to start unicorn.

=head2 stop

    $unicorn->stop;

Sends SIGQUIT to the unicorn master. This will gracefully shut down the
workers and then quit the master.

If graceful stop will not work SIGKILL will be send.

If no master is running nothing will be happening.

=head2 restart

    my $result = $unicorn->restart({ mode => 'hard' });

Mode defaults to 'graceful'.

If mode is set 'hard' graceful restart will be tried first and
$unicorn->stop plus $unicorn->start if that fails.

returns true on success, false on error.

=head2 reload

    my $result = $unicorn->reload;

Reloads the users unicorn. Reloads the config file. Code changes are
reloaded unless app_preload is set.

Basically a SIGHUP will be send to the unicorn master.

=head2 read_config

NOT YET IMPLEMENTED

    $unicorn->read_config('/path/to/config');

Reads the configuration from a unicorn config file.

=head2 write_config

NOT YET IMPLEMENTED

    $unicorn->make_config('/path/to/config');

Writes the configuration into a unicorn config file.

=head2 add_worker

    my $result = $unicorn->add_worker({ num => 3 });

Adds num workers to the users unicorn. num defaults to 1.

=head2 remove_worker

    my $result = $unicorn->remove_worker({ num => 3 });

Removes num workers but maximum of workers count -1. num defaults to 1.

=head2 query

NOT YET IMPLEMETED.

An interface to query information about running unicorns and users.

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager::CLI issue tracker

L<https://github.com/mugenken/Unicorn/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

