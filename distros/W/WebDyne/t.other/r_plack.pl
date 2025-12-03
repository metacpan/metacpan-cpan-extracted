#  Simulate a plack request
#
#  Usage SCRIPT_NAME=<filename> perl -Ilib r_plack.pl 
#
use strict;

use WebDyne qw(html);
use WebDyne::Request::PSGI;

my $raw_body='';
my $env = {
    # --- Standard CGI-like fields ---
    REQUEST_METHOD    => "GET",
    SCRIPT_NAME       => $ENV{'SCRIPT_NAME'},
    PATH_INFO         => $ENV{'PATH_INFO'},
    QUERY_STRING      => "foo=123&bar=hello",
    SERVER_NAME       => "localhost",
    SERVER_PORT       => 5000,
    SERVER_PROTOCOL   => "HTTP/1.1",
    REMOTE_ADDR       => "127.0.0.1",
    REMOTE_PORT       => 52344,
    DOCUMENT_ROOT     => '.',

    # --- HTTP headers (must be "HTTP_*" style for PSGI) ---
    HTTP_HOST                      => "localhost:5000",
    HTTP_USER_AGENT                => "Mozilla/5.0 (Macintosh; Intel Mac OS X 14.4; rv:123.0) Gecko/20100101 Firefox/123.0",
    HTTP_ACCEPT                    => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    HTTP_ACCEPT_LANGUAGE           => "en-US,en;q=0.5",
    HTTP_ACCEPT_ENCODING           => "gzip, deflate, br",
    HTTP_CONNECTION                => "keep-alive",
    HTTP_UPGRADE_INSECURE_REQUESTS => "1",
    HTTP_DNT                       => "1",    # Do Not Track
    HTTP_CACHE_CONTROL             => "max-age=0",
    HTTP_REFERER                   => "https://localhost:5000/previous",
    HTTP_COOKIE                    => "sessionid=abc123; theme=dark",

    # Typical headers a JS frontend might send:
    HTTP_ORIGIN                    => "https://localhost:5000",
    HTTP_SEC_FETCH_SITE            => "same-origin",
    HTTP_SEC_FETCH_MODE            => "navigate",
    HTTP_SEC_FETCH_USER            => "?1",
    HTTP_SEC_FETCH_DEST            => "document",

    # --- Content headers (important for POST/PUT) ---
    CONTENT_TYPE       => "application/x-www-form-urlencoded",
    CONTENT_LENGTH     => length($raw_body),

    # --- Required PSGI-specific variables ---
    "psgi.version"     => [1,1],
    "psgi.url_scheme"  => "http",
    "psgi.multithread" => 0,
    "psgi.multiprocess"=> 0,
    "psgi.run_once"    => 0,
    "psgi.streaming"   => 1,
    "psgi.nonblocking" => 0,
    "psgi.errors"      => *STDERR,
    "psgi.input"       => IO::Handle->new_from_fd(fileno(STDIN), "r"),

    # If you're simulating a POST body:
    # "psgi.input"       => IO::Handle->new_from_fd(fileno(DATA), "r"),
    # Or simpler:
    # "psgi.input"       => \$raw_body,
};


#  Get request handler and print
#
my $r=WebDyne::Request::PSGI->new(env => $env);
print html($r);
