#!perl
use 5.14.1;
use warnings;
use HTTP::Response;
use Test::Spec;
use Twitter::API::Context;
use Twitter::API::Error;

sub construct_error {
    my ( $http_status_code, $twitter_error_code, $twitter_error_text ) = @_;

    my $http_response = HTTP::Response->new($http_status_code);
    my $result = {
        errors => [
            { code => $twitter_error_code, message => $twitter_error_text },
        ]
    } if defined $twitter_error_code;
    my $context = Twitter::API::Context->new(
        http_response => $http_response,
        $result ? ( result => $result ) : (),
    );
    return Twitter::API::Error->new(context => $context);
}

describe 'Twitter::API::Error' => sub {
    it 'is always true' => sub {
        ok !!construct_error(0);
    };

    describe is_token_error => sub {
        for my $code ( 32, 64, 88, 89, 99, 135, 136, 215, 226, 326 ) {
            it "recognizes $code as a token error" => sub {
                ok construct_error(400, $code)->is_token_error;
            };
        }
    };

    describe is_token_error => sub {
        for my $code ( 34, 50, 63, 144 ) {
            it "does not recognize $code as a token error" => sub {
                ok !construct_error(400, $code)->is_token_error;
            };
        }
    };
};

runtests;
