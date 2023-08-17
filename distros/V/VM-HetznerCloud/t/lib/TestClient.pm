package # private package
    t::lib::TestClient;

use strict;
use warnings;

use Mojo::File qw(curfile path);
use Mojo::Base 'Mojo::UserAgent', -signatures;
use Mojo::Message::Response;
use Mojo::Transaction;

use experimental 'postderef';

my $base_uri = 'https://api.hetzner.cloud/v1/';

sub start ( $self, $tx, $cb ) {
    my $url = $tx->req->url;
    $url =~ s{\Q$base_uri\E}{};

    my %responses = (
        'servers/3944327' => {
            code => 200,
            file => [qw/data servers_get.txt/],
        },
        'servers' => {
            code => 200,
            file => [qw/data servers_list.txt/],
        },
        'servers?status=running' => {
            code => 200,
            file => [qw/data servers_list.txt/],
        },
        'servers?status=shutdown' => {
            code => 200,
            file => [qw/data servers_empty_list.txt/],
        },
    );

    my $response = Mojo::Message::Response->new;
    if ( !$responses{$url} ) {
        $response->code(404);
    }
    else {
        my $data         = $responses{$url};
        my $content_file = curfile->dirname->child( '..', $data->{file}->@* );

        my $content;
        $content = $content_file->slurp if -f $content_file->to_string;

        $response->code( $data->{code} );
        $response->body( $content ) if length $content;
        $response->headers->content_type( $data->{ct} // 'application/json' );
    }

    return $tx->res( $response );
}

1;