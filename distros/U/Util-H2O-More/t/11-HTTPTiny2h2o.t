# basically how Util::H2O::h2o does it
use strict;
use warnings;

use Test::More q//;
use Test::Exception;
use JSON::MaybeXS;
use Util::H2O::More qw/ddd HTTPTiny2h2o o2d/;

my $AoH = [ { four => 4, five => 5, six => 6 }, { seven => 7, eight => 8, nine => 9 }, ];

my $HTTPTiny_response1 = {
  status  => 200,
  content => encode_json($AoH),
};

HTTPTiny2h2o $HTTPTiny_response1;

is_deeply o2d($HTTPTiny_response1->content), $AoH, q{Arrays of hashes encoded as JSON was decoded properly};

my $HoAoH = {
    one   => [qw/1 2 3 4 5/],
    two   => [qw/6 7 8 9 0/],
    three => [ { four => 4, five => 5, six => 6 }, { seven => 7, eight => 8, nine => 9 }, ],
    ten   => {
        eleven    => [qw/11 12 13 14 15 16 17 18 19 20/],
        twentyone => [
            {
                twentytwo => 22,
            },
            {
                twentythree => 23,
            },
            {
                twentyfour => 24,
                twentyfive => 25,
                twentysix  => 26,
            },
        ],
        thirteen => 13,
    },
};

my $HTTPTiny_response2 = {
  status  => 200,
  content => encode_json($HoAoH), 
};

HTTPTiny2h2o $HTTPTiny_response2;

is $HTTPTiny_response2->content->ten->thirteen, 13, q{Accessor for deeply nested key found as expected};

is $HTTPTiny_response2->content->ten->doesntexist, undef, q{'undef' returned for non-existing key, due to internal use of 'd2o -autoundef'};

is_deeply o2d($HTTPTiny_response2->content), $HoAoH, q{Deep hash of arrays of hashes encoded as JSON was decoded properly};

is $HTTPTiny_response2->content->doesnotexist, undef, q{handles 'content' that points to undef setting it -autoundef};

my $bad_json1 = {
  status  => 200,
  content => 'this is definitely not JSON',
};

dies_ok { HTTPTiny2h2o -autothrow, $bad_json1 } q{non-JSON in 'content' of the response object causes decode_json to die}; 

my $bad_json2 = {
  status  => 200,
  content => 'this is definitely not JSON',
};

HTTPTiny2h2o $bad_json2;
is $bad_json2->content, q{this is definitely not JSON}, q{not using '-autothrow' on bad JSON returns original content via ->content accessor};
like ref $bad_json2, qr/Util::H2O/, q{ref type of response reference is Util::H2O};
is ref $bad_json2->content, "", q{ref type of ->content is empty string};

my $bad_resp = {
  status  => 200,
};

dies_ok { HTTPTiny2h2o $bad_resp} q{missing 'content' HASH key in provided reference cause pre-check to die}; 

# content is an empty
my $HTTPTiny_response3 = {
  status  => 200,
  content => undef,
};

HTTPTiny2h2o $HTTPTiny_response3;

is $HTTPTiny_response3->content->doesnotexist, undef, q{handles 'content' that points to undef setting it -autoundef};

note "Testing JSON containers other than expected HASH - still underdeveloped area";
# content is an empty array
my $HTTPTiny_response4 = {
  status  => 200,
  content => "[]",
};

HTTPTiny2h2o $HTTPTiny_response4;
is $HTTPTiny_response4->content->get(1), undef, q{empty JSON array makes 'get' AREF vmethod return undef };
is $HTTPTiny_response4->content->scalar, 0, q{empty JSON array makes 'scalar' AREF vmethod return undef };

done_testing;
