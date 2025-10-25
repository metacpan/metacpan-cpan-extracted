#!/usr/bin/perl -w

#
# Usage:
#
#     MYAPP_DEBUG=1 perl myapp.pl daemon -l http://*:8080
#

use Mojo::Base -strict;
use Mojo::File qw/ curfile path /;

use lib qw/lib/;

use MyApp;

use constant DEBUG => !!$ENV{MYAPP_DEBUG};

my $root = curfile->dirname->child('test')->to_string;

$ENV{MOJO_MODE} ||= 'production' unless DEBUG; # production
$ENV{MOJO_LOG_LEVEL} ||= DEBUG ? 'debug' : 'info';

MyApp->new(
    debugmode       => DEBUG,
    loglevel        => $ENV{MOJO_LOG_LEVEL},
    mysecret        => 'Li$MyExp1',

    project_name    => 'MyApp',
    project_version => '0.01',
    moniker         => 'myapp',

    documentroot    => path($root)->child('www')->make_path->to_string,
    homedir         => curfile->dirname->child('www')->make_path->to_string,
    datadir         => path($root)->child('var')->make_path->to_string,
    tempdir         => path($root)->child('tmp')->make_path->to_string,
    logfile         => DEBUG ? undef : path($root)->child('log')->make_path->child('myapp.log')->to_string,

    config_opts     => {
        noload => 1, # force disable loading config from file
        defaults => {
            foo => 'bar',
            suffitauth => { # SuffitAuth Client Setting
                serverurl   => 'https://auth.localhost/api',
                insecure    => 1,
                authscheme  => 'Bearer',
                token       => 'eyJhbGciOiJSUzI1NiIs...kpXVCJ9.eyJjaWQiOiJiM',
            },
        },
    },
)->start;

1;

__END__
