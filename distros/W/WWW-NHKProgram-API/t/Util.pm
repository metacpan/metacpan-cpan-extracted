package t::Util;
use strict;
use warnings;
use utf8;
use Scope::Guard;

sub mock_furl_response {
    my ($status, $data) = @_;

    return sub {
        my $original_furl_response_new = *Furl::Response::new{CODE};
        undef *Furl::Response::new;
        *Furl::Response::new = sub {
            my ($class, $minor_version, $code, $message, $headers, $content) = @_;
            bless {
                minor_version => $minor_version,
                code    => $status,
                message => $message,
                headers => Furl::Headers->new($headers),
                content => $data,
            }, $class;
        };

        return Scope::Guard->new(sub {
            undef *Furl::Response::new;
            *Furl::Response::new = $original_furl_response_new;
        });
    }
}

1;

