use strict;
use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Data::Dumper;
use Test::More;
use JSON::Syck;

my $HAS_JSON = 0;

BEGIN {
    unless ( defined &utf8::encode ) {
        plan skip_all => 'No Unicode support';
        exit;
    }
    eval { require JSON; $HAS_JSON = 1 };
    if ( $HAS_JSON && $JSON::VERSION >= 2 && $JSON::VERSION < 2.11 ) {
        plan skip_all => 'JSON compatibility broken since JSON 2.0';
        exit;
    }
}

use Storable;

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse  = 1;

my @tests = (
    '"foo"',
    '[1, 2, 3]',
    '[1, 2, 3]',
    '2',
    '"foo\'bar"',
    '[1,2,3]',
    '{"foo": "bar"}',
    '{"foo":"bar"}',
    '[{"foo": 2}, {"foo": "bar"}]',
    qq("\xe5\xaa\xbe"),
    'null',
    '{"foo":null}',
    '""',
    '[null,null]',
    '["",null]',
    '{"foo":""}',
    '["\"://\""]',
    '"~foo"',
    { TEST => '"\/"',     TODO => "backslashed char not working yet" }, # escaped solidus
    '"\""',
    { TEST => '"\b"',     TODO => "backslashed char not working yet" },
    { TEST => '"\f"',     TODO => "backslashed char not working yet" },
    { TEST => '"\n"',     TODO => "backslashed char not working yet" },
    { TEST => '"\r"',     TODO => "backslashed char not working yet" },
    { TEST => '"\t"',     TODO => "backslashed \\t not working yet" },
    { TEST => '"\u0001"', TODO => "backslashed \\u not working yet" },
);

plan tests => scalar @tests * ( 2 + $HAS_JSON ) * 2;

TODO: {
    for my $test_orig (@tests) {
        for my $single_quote ( 0, 1 ) {
            for my $unicode ( 0, 1 ) {
                local $JSON::Syck::SingleQuote     = $single_quote;
                local $JSON::Syck::ImplicitUnicode = $unicode;
                my $test = $test_orig;

                local $TODO;
                if ( ref $test eq 'HASH' ) {
                    if ($single_quote or substr($test->{TEST},2,1) =~ m|[u/]|) {
                        $TODO = $test->{TODO};
                    }
                    $test = $test->{TEST};
                }

                if ($single_quote) {
                    $test =~ s/'/\\'/g;
                    $test =~ s/"/'/g;
                }

                my $data = eval { JSON::Syck::Load($test) };
                my $json = JSON::Syck::Dump($data);

                #diag("json: $json");
                utf8::encode($json) if !ref($json) && $unicode;

                # don't bother white spaces
                for ( $test, $json ) {
                    s/([,:]) /$1/eg;
                }

                my $desc = "roundtrip $test -> " . Dumper($data)
                  . " -> $json -> sq:$single_quote utf8:$unicode ";
                utf8::encode($desc);
                is $json, $test, $desc;

                # try parsing the data with JSON.pm
                if ( $HAS_JSON and !$single_quote ) {
                    $SIG{__WARN__} = sub { 1 };
                    utf8::encode($data) if defined($data) && !ref($data) && $unicode;
                    my $data_pp = eval { JSON::jsonToObj($json) };
                    is_deeply $data_pp, $data, "compatibility with JSON.pm $test";
                }
            }
        }
    }
}

