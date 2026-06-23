#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use WWW::Gitea;

# A minimal LWP::UserAgent stand-in that records the requests it is handed and
# always replies with an empty JSON array, so we can assert which query string
# the resource controllers actually send.
package MockUA {
    sub new { bless { requests => [] }, shift }
    sub requests { $_[0]->{requests} }
    sub request {
        my ($self, $req) = @_;
        push @{ $self->{requests} }, $req;
        return HTTP::Response->new(
            200, 'OK', [ 'Content-Type' => 'application/json' ], '[]');
    }
}

my $mock  = MockUA->new;
my $gitea = WWW::Gitea->new(
    url   => 'https://gitea.example.com',
    token => 'SECRET',
    ua    => $mock,
);

sub last_uri { $mock->requests->[-1]->uri }

# labels->list now forwards pagination query parameters.
$gitea->labels->list('getty', 'p5-www-gitea', limit => 50, page => 2);
like( last_uri(), qr{/repos/getty/p5-www-gitea/labels\b}, 'labels->list path' );
like( last_uri(), qr/\blimit=50\b/, 'labels->list forwards limit' );
like( last_uri(), qr/\bpage=2\b/,   'labels->list forwards page' );

# issues->comments now forwards query parameters too.
$gitea->issues->comments('getty', 'p5-www-gitea', 7, limit => 50, page => 3);
like( last_uri(), qr{/repos/getty/p5-www-gitea/issues/7/comments\b},
    'issues->comments path' );
like( last_uri(), qr/\blimit=50\b/, 'issues->comments forwards limit' );
like( last_uri(), qr/\bpage=3\b/,   'issues->comments forwards page' );

# issues->list already forwarded query — guard against regressions.
$gitea->issues->list('getty', 'p5-www-gitea', state => 'all', limit => 50);
like( last_uri(), qr/\bstate=all\b/, 'issues->list forwards state' );
like( last_uri(), qr/\blimit=50\b/,  'issues->list forwards limit' );

# No query args: no spurious query string.
$gitea->labels->list('getty', 'p5-www-gitea');
unlike( last_uri(), qr/\?/, 'labels->list without args sends no query string' );

done_testing;
