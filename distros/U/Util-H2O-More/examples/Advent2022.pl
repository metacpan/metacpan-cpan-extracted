use strict;
use warnings;
use JSON       qw//;
use HTTP::Tiny qw//;
use Util::H2O::More qw/d2o/;

# give's Santa "$response->content", "$response->status", "$response->success", etc
# from HTTP::Tiny's response object (pure HASH)

my $http = HTTP::Tiny->new;
my $response = d2o $http->get(q{https://jsonplaceholder.typicode.com/users});

# check for unsuccessful web request
if (not $response->success) {
    print STDERR qq{Can't get list of online persons to watch!\n};
    printf STDERR qq{Web request responded with with HTTP status: %d\n}, $response->status;
    exit 1;
}

# decode JSON from response content
my $json_array_ref = d2o JSON::decode_json($response->content); # $json is an ARRAY reference

print qq{lat, lng, name, username\n};

foreach my $person ($json_array_ref->all) {
    printf qq{%5.4f, %5.4f, %s, %s\n},
     $person->address->geo->lat,   # deep chain of accessors from '-recurse'
     $person->address->geo->lng,   # deep chain of accessors from '-recurse'
     $person->name,
     $person->username;
}
__END__
