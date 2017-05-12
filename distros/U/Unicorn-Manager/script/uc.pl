#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

$| = 1;

use Getopt::Long qw(:config pass_through);

use Unicorn::Manager::CLI;
use IO::Socket;
use JSON;

my $HELP = <<"END";
Synopsis
    $0 [action] [options]

Actions
    help
        show this help
    show
        dumps a structure of user ids and the process ids of masters
        and their children
    start
        starts a users unicorn server, requires --config to be specified
    stop
        stops unicorn
    restart
        gracefully restarts unicorn
    reload
        reload unicorn
    add_worker
        adds a unicorn worker
    rm_worker
        removes a unicorn worker
    version
        print Unicorn::Manager version
    query
        to be implemented

Options
    -u, --user
        username of unicorns owner (can be ommited if user is not root)
    -c, --config
        path to the unicorn config file
    --args
        optional additional arguments used with action 'start'
        overrides options of the config file
        see section Examples for proper usage
        "-D" is set default
    --debug
        flag to enable debug output
    --rails
        defaults to 1 for now. so it has no effect at all

Examples
    uc.pl show
    uc.pl start -u railsuser -c /home/railsuser/app/unicorn.rb --args "--listen 0.0.0.0:80, -D"
    uc.pl restart -u railsuser
    uc.pl add_worker

END

my $user;
my $config;
my $host;
my $port  = 4242;
my $args  = undef;
my $DEBUG = 0;
my $rails = 1;

my $result = GetOptions(
    'user|u=s'   => \$user,
    'config|c=s' => \$config,
    'args=s'     => \$args,
    'debug'      => \$DEBUG,
    'rails'      => \$rails,
    'host|h=s'   => \$host,
    'port|p=i'   => \$port,
);

my ( $action, @params ) = @ARGV;

if ( $> > 0 ) {
    $user = getpwuid $> unless $user;
}
else {
    $user = 'nobody' unless $user;
}

unless ( $user && $action ) {
    print $HELP;
    die "Missing arguments. username and action are required\n";
}

my $arg_ref = [];

# make -D default as most of the time you will want to start Unicorn as daemon
$args = "-D" unless defined $args;

$arg_ref = [ split ',', $args ] if $args;

my $unicorn = sub {
    return Unicorn::Manager::CLI->new(
        username => $user,
        rails    => $rails,
        DEBUG    => $DEBUG,
    );
};

my $dispatch_cli = {
    help => sub {
        say $HELP;
        exit 0;
    },
    show => sub {
        my $uc = Unicorn::Manager::CLI->new(
            username => 'nobody',
            DEBUG    => $DEBUG,
        );

        my $uidref = $uc->proc->process_table->ptable;

        for ( keys %{$uidref} ) {
            my $username = getpwuid $_;
            my $pidref   = $uidref->{$_};

            print "$username:\n";

            for my $master ( keys %{$pidref} ) {
                print "    master: $master\n";
                for my $worker ( @{ $pidref->{$master} } ) {
                    if ( ref($worker) ~~ 'HASH' ) {
                        for ( keys %$worker ) {
                            print "        new master: " . $_ . "\n";
                            print "            new worker: $_\n" for @{ $worker->{$_} };
                        }
                    }
                    else {
                        print "        worker: $worker\n";
                    }
                }
            }
        }

        exit 0;
    },
    start => sub {
        unless ($config) {
            print $HELP;
            die "Action 'start' requires a config file.\n";
        }
        if ($DEBUG) {
            say "\$unicorn->start( config => \$config, args => \$arg_ref )";
            say " -> \$config => $config";
            use Data::Dumper;
            say " -> \$arg_ref => " . Dumper($arg_ref);
        }
        return $unicorn->()->start( { config => $config, args => $arg_ref } );
    },
    stop => sub {
        return $unicorn->()->stop;
    },
    restart => sub {
        return $unicorn->()->restart( { mode => 'graceful' } );
    },
    reload => sub {
        return $unicorn->()->reload;
    },
    add_worker => sub {
        return $unicorn->()->add_worker( { num => 1 } );
    },
    rm_worker => sub {
        return $unicorn->()->remove_worker( { num => 1 } );
    },
    version => sub {
        return Unicorn::Manager::Version->get;
    },
    query => sub {
        $params[0] = 'help' unless @params;
        return $unicorn->()->query(@params);
    },
};

my $dispatch_server = {
    query => sub {
        my ( $query, @args ) = @params;
        my $data = {
            query => $query,
            args  => [@args],
        };
        my $json = JSON->new->utf8(1);

        my $sock = IO::Socket::INET->new(
            PeerAddr => $host || 'localhost',
            PeerPort => $port || 4242,
            Proto    => 'tcp',
        );

        my $json_string = $json->encode($data);
        my $res;

        if ( not $sock ) {
            say "Apparently the Unicorn::Manager::Server is not running or not accessible.";
            say "Try running without the host command line switch or check your firewall.";

            exit 1;
        }

        print $sock "$json_string\n";

        while (<$sock>) {
            $res .= $_;
        }

        close $sock;

        return $res;
    },
};

my $response;
my $no_such_action = sub {
    say "No action $action defined";
    exit 1;
};

if ($host) {
    if ( exists $dispatch_server->{$action} ) {
        $response = $dispatch_server->{$action}->();
    }
    else {
        $no_such_action->();
    }
}
else {
    if ( exists $dispatch_cli->{$action} ) {
        $response = $dispatch_cli->{$action}->();
    }
    else {
        $no_such_action->();
    }
}

say $response;

exit 0;

__END__

=head1 NAME

uc.pl - A Perl script to manage instances of the Unicorn webserver

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.006009

=head1 SYNOPSIS

uc.pl is included in the Unicorn::Manager package.

=head1 USAGE

The help and usage information of uc.pl

    Synopsis
        uc.pl [action] [options]

    Actions
        help
            show this help
        show
            dumps a structure of user ids and the process ids of masters
            and their children
        start
            starts a users unicorn server, requires --config to be specified
        stop
            stops unicorn
        restart
            gracefully restarts unicorn
        reload
            reload unicorn
        add_worker
            adds a unicorn worker
        rm_worker
            removes a unicorn worker
        version
            print Unicorn::Manager version
        query
            to be implemented

    Options
        -u, --user
            username of unicorns owner (can be ommited if user is not root)
        -c, --config
            path to the unicorn config file
        --args
            optional additional arguments used with action 'start'
            overrides options of the config file
            see section Examples for proper usage
            "-D" is set default
        --debug
            flag to enable debug output
        --rails
            defaults to 1 for now. so it has no effect at all

    Examples
        uc.pl show
        uc.pl start -u railsuser -c /home/railsuser/app/unicorn.rb --args "--listen 0.0.0.0:80, -D"
        uc.pl restart -u railsuser
        uc.pl add_worker


=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager issue tracker

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


