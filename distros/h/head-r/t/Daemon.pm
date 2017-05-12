### Daemon.pm --- Employ HTTP::Daemon for testing purposes  -*- Perl -*-

### Ivan Shmakov, 2013

## To the extent possible under law, the author(s) have dedicated all
## copyright and related and neighboring rights to this software to the
## public domain worldwide.  This software is distributed without any
## warranty.

## You should have received a copy of the CC0 Public Domain Dedication
## along with this software.  If not, see
## <http://creativecommons.org/publicdomain/zero/1.0/>.

### Code:
package t::Daemon;

use common::sense;
use English qw (-no_match_vars);

my ($class, $hostname) = do {
    open (my $localhost, "<", "+localhost")
        or die ("+localhost: ", $!);
    map { chomp (); $_; } (<$localhost>);
};

# require Data::Dump;
require Encode;
require HTTP::Daemon;
require HTTP::Response;
require HTTP::Status;
require Scalar::Util;

## FIXME: work-around the lack of IPv6 support in HTTP::Daemon
if ($class ne "IO::Socket::INET") {
    eval ("require " . $class . ";");
    foreach my $a (\@HTTP::Daemon::ISA,
                   \@HTTP::Daemon::ClientConn::ISA) {
        for (my $i = 0; $i <= $#$a; $i++) {
            $a->[$i]
                = $class
                if ($a->[$i] eq "IO::Socket::INET");
        }
    }
}

## FIXME: this function is not IPv6-enabled, either
sub HTTP::Daemon::url {
    my ($self) = @_;
    ## .
    return ($self->_default_scheme ()
            . "://" . $hostname
            . ":"   . $self->sockport ()
            . "/");
}

sub dir_list {
    my ($node) = @_;
    my $html
        =  ("<!DOCTYPE html>\n"
            . "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n"
            . "<head><title></title></head>\n"
            . "<body>\n<ul>\n");
    foreach (sort { $a cmp $b; } (keys (%$node))) {
        my $href
            = ($_ . (Scalar::Util::blessed ($node->{$_}) ? "" : "/"));
        $html
            .= ("<li><a href=\"" . $href
                . "\">" . $href . "</a></li>\n");
    }
    $html
        .= "</ul>\n</body>\n";
    my $content
        = Encode::encode_utf8 ($html);
    ## .
    HTTP::Response->new  ("200", undef, [
                              "Content-Length"
                                  => length ($content),
                              "Content-Type"
                                  => "text/html; charset=utf-8"
                          ], $content);
}

sub handle_path {
    my ($node, $path) = @_;
    ## .
    return undef
        unless ($path =~ /^\//);
    while ((my ($head, $tail)
            = ($path =~ m (^/ ([^/]+) (/.*)$)x))) {
        my $next
            = $node->{$head};
        ## .
        return undef
            unless (ref ($next) eq "HASH"
                    && ! Scalar::Util::blessed ($next));
        ($node, $path)
            = ($next, $tail);
    }
    ## NB: dropping leading slash
    ## .
    return ($path eq "/"
            ? dir_list ($node)
            : $node->{substr ($path, 1)});
}

sub run_http_daemon {
    my ($content, $daemon) = @_;

    my $handle = sub {
        ## .
        handle_path ($content, $_[0]->uri ()->path ());
    };

    while ((my $conn = $daemon->accept ())) {
        # warn ("D: Got connection: ", scalar (Data::Dump::dump ($conn)));
        while ((my $r = $conn->get_request ())) {
            # warn ("D: Got request: ", scalar (Data::Dump::dump ($r)));
            my $response
                = undef;
            unless (($r->method () eq "GET"
                     || $r->method () eq "HEAD")
                    && defined ($response = $handle->($r))) {
                $conn->send_error (HTTP::Status::RC_FORBIDDEN ());
                next;
            }
            $response->content ("")
                if ($r->method () eq "HEAD");
            # warn ("D: Response: ", scalar (Data::Dump::dump ($response)));
            $conn->send_response ($response);
        }
    }
}

## .
1;

### Emacs trailer
## Local variables:
## coding: us-ascii
## End:
### Daemon.pm ends here
