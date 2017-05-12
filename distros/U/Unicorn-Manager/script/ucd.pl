#!/usr/bin/perl

use 5.010;
use warnings;
use Getopt::Long qw(:config pass_through);

use Unicorn::Manager::Server;
use Proc::Daemon;

my $HELP = <<"END";
Synopsis
    $0 [options]

Options
    -u, --user
        username of unicorns owner (can be ommited if user is not root)
    -p, --port
        port to listen on

END

my $user   = undef;
my $port   = undef;
my $daemon = 1;

my $result = GetOptions(
    'user|u=s'   => \$user,
    'port|p=s'   => \$port,
    'daemon|d=s' => \$daemon,
);

my $server = Unicorn::Manager::Server->new( user => $user, );

Proc::Daemon::init if $daemon;

$server->run();

