#!perl
use 5.14.1;
use warnings;
use Test::Spec;

use Twitter::API;

describe upload_media => sub {
    my $client;
    before each => sub {
        $client = Twitter::API->new_with_traits(
            traits              => 'ApiMethods',
            consumer_key        => 'key',
            consumer_secret     => 'secret',
            access_token        => 'token',
            access_token_secret => 'token-secret',
        );
        $client->stubs(send_request => sub { return });
    };

    context 'positional media parameter' => sub {
        my $req;
        before each => sub {
            my $context = $client->upload_media(
                [ undef, 'file.dat', content => 'data' ],
            );
            $req = $context->http_request;
        };

        it 'has content-type miltipart/form-data' => sub {
            is $req->content_type, 'multipart/form-data';
        };
        it 'has part with name "media"' => sub {
            my ( $part ) = $req->parts;
            my $disposition = $part->header('content_disposition');
            like $disposition, qr/\bname="media"/;
        };
        it 'has part with filename' => sub {
            my ( $part ) = $req->parts;
            my $disposition = $part->header('content_disposition');
            like $disposition, qr/\bfilename="file\.dat"/;
        };
        it 'has part with expected content' => sub {
            my ( $part ) = $req->parts;
            is $part->content, 'data';
        };
    };
    context 'positional media_data parameter' => sub {
        my $req;
        before each => sub {
            my $context = $client->upload_media(
                'base64 data here',
            );
            $req = $context->http_request;
        };

        it 'has content-type miltipart/form-data' => sub {
            is $req->content_type, 'multipart/form-data';
        };
        it 'has part with name "media_data"' => sub {
            my ( $part ) = $req->parts;
            my $disposition = $part->header('content_disposition');
            like $disposition, qr/\bname="media_data"/;
        };
        it 'has part with expected content' => sub {
            my ( $part ) = $req->parts;
            is $part->content, 'base64 data here';
        };
    };
    context 'with additional_owners' => sub {
        my $req;
        before each => sub {
            my $context = $client->upload_media({
                media_data        => 'test',
                additional_owners => [ 1..5 ],
            });
            $req = $context->http_request;
        };

        it 'flattens additional_owners' => sub {
            my ( $part ) = grep {
                $_->header('content_disposition') =~ /\bname="additional_owners"/;
            } $req->parts;
            is $part->content, '1,2,3,4,5';
        };
    };
};

runtests;
