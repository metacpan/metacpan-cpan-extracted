#! perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Basename;
use IO::CaptureOutput qw(capture);

# check whether we can talk to ourself or not ...
# ...

delete $ENV{PERL_LWP_ENV_PROXY};

use Config;
my $perl = $Config{'perlpath'};
$perl = $^X if $^O eq 'VMS' or -x $^X and $^X =~ m,^([a-z]:)?/,i;

my $loc = dirname($0);

$| = 1;    # autoflush

# First we ensure that we can talk to ourself ...

system( $perl, File::Spec->catfile( $loc, "talk-to-ourself.pl" ) );
my $status = $?;
$status and BAIL_OUT("Can't talk to ourself");

require IO::Socket;         # make sure this work before we try to make a HTTP::Daemon
use POSIX ":sys_wait_h";    # for nonblocking read

# Seconds we make a daemon in another process

my ( $daemon_pipe, $daemon_pid );
local $SIG{CHLD} = sub {
    local ( $!, $? );
    my $pid = waitpid( -1, WNOHANG );
    $pid == $daemon_pid or return;
    $daemon_pid = undef;
    close($daemon_pipe);
    $daemon_pipe = undef;
};

$daemon_pid = open( $daemon_pipe,
           "$perl " . File::Spec->catfile( $loc, "mock-daemon.pl" ) . " --httpd-opts Timeout=10  --httpd-opts hdf=1 |" )
  or die "Can't exec daemon: $!";

END { $daemon_pid and kill( $daemon_pid => 0 ); $daemon_pipe and close($daemon_pipe); }

my $greeting = <$daemon_pipe>;
$greeting =~ /(<[^>]+>)/;

require URI;
my $base = URI->new($1);

sub url
{
    my $u = URI->new(@_);
    $u = $u->abs( $_[1] ) if @_ > 1;
    $u->as_string;
}

note "Will access HTTP server at $base\n";

use WWW::Mechanize::Script;

my %cfg = (
     "defaults" => {
                     "check" => {
                                  "code_cmp"              => ">",
                                  "response_code"         => 2,
                                  "min_bytes_code"        => 2,
                                  "max_bytes_code"        => 1,
                                  "regex_forbid_code"     => 2,
                                  "regex_require_code"    => 2,
                                  "text_forbid_code"      => 2,
                                  "text_require_code"     => 2,
                                  "min_elapsed_time_code" => 1,
                                  "max_elapsed_time_code" => 2,
                                },
                     "request" => { "method" => "GET" }
                   },
     "templating" => {
         "vars" =>
           { "CODE_NAMES" => [ "OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT", "EXCEPTION" ] },
     },
     "summary" => {
                "template" =>
                  "[% CODE_NAMES.\$CODE; IF MESSAGES.size > 0 %] - [% MESSAGES.join(', '); END %]\n",
                "target" => "-"
     },
     "report" => {
                   "template" => "[% USE Dumper; Dumper.dump(RESPONSE) %]",
                   "target"   => "-"
                 }
          );
my @script = (
    {
       "request" => {
                      "method" => "get",
                      "uri"    => url("/etc/passwd", $base),
                    },
       "check" => {
                    "test_name"    => "passwd1",
                    "text_require" => [ "/root", "daemon", ":bin:" ],
                    "text_forbid"  => [ "staff", ],
                  },
    },
    {
       "request" => {
                      "method" => "get",
                      "uri"    => url("/etc/passwd", $base),
                    },
       "check" => {
                    "test_name" => "passwd2",
                    "min_rtime" => "0.01",
                    "max_rtime" => "1",
                  },
    },
    {
       "request" => {
                      "method" => "get",
                      "uri"    => url("/etc/passwd", $base),
                    },
       "check" => {
                    "test_name" => "passwd3",
                    "min_bytes" => "1",
                    "max_bytes" => "65536",
                  },
    },
    {
       "request" => {
                      "method" => "get",
                      "uri"    => url("/etc/passwd", $base),
                    },
       "check" => {
           "test_name"     => "passwd4",
           "regex_require" => [
                                "(?:\\:\\d){2}",    # uid/gid
                                "(?:/\\w+){2}",     # shell ;)
                              ],
           "regex_forbid" => [ "^\\w+:\\w{2,}", ],  # password
                  },
    },
    {
       "request" => {
                      "method" => "get",
                      "uri"    => url("/etc/master.passwd", $base),
                    },
       "check" => {
           "test_name"     => "exit_status",
	   "response" => 418,
	},
    }
             );

my $wms = WWW::Mechanize::Script->new( \%cfg );

isa_ok($wms, "WWW::Mechanize::Script") or BAIL_OUT("Need WWW::Mechanize::Script");

my ( $code, @msgs ) = (0);
my ( $stdout, $stderr );
#capture {
eval { ( $code, @msgs ) = $wms->run_script(@script); };
#} \$stdout, \$stderr;

cmp_ok($code, '==', 0, "Test script runs without error");
is_deeply( \@msgs, [], "No messages" );

done_testing();
