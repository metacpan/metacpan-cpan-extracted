package WWW::SnipeIT::Users;
use Modern::Perl '2018';

use Object::Pad;

use HTTP::Request;
use LWP::UserAgent;
use JSON::XS;
use URI;

class Users {

    field $endpoint :param;
    field $header :param;

    #key=value
    method getUsers (%params) {
        my $uri = URI->new($endpoint."users");
        while (my ($key, $value) = each %params) {
            $uri->query_param($key => $value);
        }
        my $r = HTTP::Request->new('GET', $uri->as_string, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results;
    }

    method getUsersAssets ($user_id) {
        my $url = $endpoint."users/".$user_id."/assets";
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results;
    }
}
1;