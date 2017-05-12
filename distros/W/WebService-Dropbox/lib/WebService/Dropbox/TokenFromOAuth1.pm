package WebService::Dropbox::TokenFromOAuth1;
use strict;
use warnings;
use JSON;
use Net::OAuth;
use LWP::UserAgent;

sub token_from_oauth1 {
    my ($class, $args) = @_;
    my $request = Net::OAuth->request('protected resource')->new(
        consumer_key => $args->{consumer_key},
        consumer_secret => $args->{consumer_secret},
        request_url => 'https://api.dropboxapi.com/1/oauth2/token_from_oauth1',
        request_method => 'POST',
        signature_method => 'PLAINTEXT', # HMAC-SHA1 can't delete %20.txt bug...
        timestamp => time,
        nonce => &nonce,
        token => $args->{access_token},
        token_secret => $args->{access_secret},
    );
    $request->sign;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->post($request->to_url);
    if ($res->is_success) {
        my $data = decode_json($res->decoded_content);
        return $data->{access_token};
    }
    warn $res->decoded_content;
    return;
}

sub nonce {
    my $length = 16;
    my @chars = ( 'A'..'Z', 'a'..'z', '0'..'9' );
    my $ret;
    for (1..$length) {
        $ret .= $chars[int rand @chars];
    }
    return $ret;
}

1;
