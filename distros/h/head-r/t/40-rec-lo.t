### 40-rec-lo.t --- Test against local HTTP::Daemon  -*- Perl -*-

### Code:

use common::sense;
use English qw (-no_match_vars);
use Test::More;

use lib ".";

require Encode;
require HTTP::Daemon;
require HTTP::Response;
require t::Daemon;

sub text_plain {
    my $content
        = Encode::encode_utf8 ($_[0]);
    ## .
    HTTP::Response->new  (200, undef, [
                              "Content-Length"
                                  => length ($content),
                              "Content-Type"
                                  => "text/plain; charset=utf-8"
                          ], $content);
}

my $content = {
    "foo" => {
        "bar" => text_plain ("Foo!\n"),
        "baz" => {
            "qux" => text_plain ("Kilroy was here\n")
        },
        "ignored~"  => text_plain ("This entry will be ignored\n")
    },
    "hello" => text_plain ("Hello, world!\n")
};

if (@ARGV > 0 && $ARGV[0] eq "--daemon") {
    my $daemon
        = HTTP::Daemon->new ();
    print ($daemon->url (), "\n");
    t::Daemon::run_http_daemon ($content, $daemon);
    ## .
    exit;
}

## NB: only after we have spawned the daemon can we set the plan
plan ((-s "+localhost")
      ? qw (tests 1)
      : ("skip_all",  "Now known way to contact localhost?"));

my @d_cmd
    = ($EXECUTABLE_NAME, $PROGRAM_NAME, "--daemon");
my $daemon_pid
    = open (my $daemon, "-|", @d_cmd)
    or die ("Cannot run ", join (" ", @d_cmd), ": ", $!);
my $uri
    = <$daemon>;
chomp ($uri);

## FIXME: shouldn't it be done in head-r itself?
delete ($ENV{"PERL_LWP_ENV_PROXY"});

sub run_head_r {
    my @cmd
        = ($EXECUTABLE_NAME, "head-r",
           "--no-proxy", "--wait=.1", @_);
    note ("Spawning: ", join (" ", @cmd));
    ## .
    open (my $fh, "-|", @cmd)
        or return undef;
    ## .
    $fh;
}

sub hack_head_r_output {
    my ($s) = @_;
    note ("Got from head-r: ", $s);
    ## .
    my ($uri, $data, $depth, $length, $code)
        = ($_[0] =~  m {^ ([[:alnum:]]+://[^[:blank:]\n]+)
                        (\t  [0-9]+  \t ([0-9]+)
                         \t ([0-9]*) \t ([0-9]{3}))?
                        \n? $}x)
        or return undef;
    ## .
    [ $uri,
      ($data ne "" ? ("XXX", $depth, $length, $code) : ()) ];
}

sub response_length_code {
    my ($path) = @_;
    ## .
    my $response
        = t::Daemon::handle_path ($content, $path)
        or return undef;
    ## .
    return ($response->content_length (),
            $response->code ());
}

my @common_args
    = (qw (--descend-re=/$ --info-re=[^~]$));

subtest "Basic testing at --depth=2"
    =>  sub {
        my $rlc
            = \&response_length_code;
        my $head_r
            = run_head_r ("--depth=2", @common_args,
                          "--", $uri);
        ok (defined ($head_r), "spawned head-r");
        is_deeply (hack_head_r_output (scalar (<$head_r>)),
                   [ $uri, "XXX", 2, $rlc->("/") ],
                   ($uri));
        is_deeply (hack_head_r_output (scalar (<$head_r>)),
                   [ $uri . "foo/", "XXX", 1, $rlc->("/foo/") ],
                   ($uri  . "foo/"));
        is_deeply (hack_head_r_output (scalar (<$head_r>)),
                   [ $uri . "foo/bar", "XXX", 0,
                     $rlc->("/foo/bar") ],
                   ($uri  . "foo/bar"));
        is_deeply (hack_head_r_output (scalar (<$head_r>)),
                   [ $uri . "foo/baz/", "XXX", 0,
                     $rlc->("/foo/baz/") ],
                   ($uri  . "foo/baz/"));
        is_deeply (hack_head_r_output (scalar (<$head_r>)),
                   [ $uri . "foo/ignored~" ],
                   ($uri  . "foo/ignored~"));
        is_deeply (hack_head_r_output (scalar (<$head_r>)),
                   [ $uri . "hello", "XXX", 1,
                     $rlc->("/hello") ],
                   ($uri  . "hello"));
    };

## shutdown the daemon
kill ("QUIT", $daemon_pid);

### Emacs trailer
## Local variables:
## coding: us-ascii
## End:
### 40-rec-lo.t ends here
