# perl
# t/004-passthru.t - test Text::CSV options passed through by
# Text::CSV::Hashify->new()
use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype looks_like_number );
use Text::CSV::Hashify;
use Test::More tests => 10;

my ($obj, $source, $key, $k, $href);

{
    $source = "./t/data/whitespace_names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
            allow_whitespace => 1,
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    $k = { 
        id => 1,
        ssn => '999-99-9999',
        first_name => 'Alice',
        last_name => 'Zoltan',
        address => '360 5 Avenue, Suite 1299',
        city => 'New York',
        state => 'NY',
        zip => '10001',
    };
    $href = $obj->record(1);
    is_deeply($href, $k, "'allow_whitespace' works");
    $k = { 
        id => 7,
        ssn => '999-99-9993',
        first_name => 'Guinevere',
        last_name => 'Tyler',
        address => '1 Kodiak Hwy',
        city => 'Kodiak',
        state => 'AK',
        zip => '98989',
    };
    $href = $obj->record(7);
    is_deeply($href, $k, "'allow_whitespace' works");
}

{
    $source = "./t/data/pipe_names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
            sep_char => '|',
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    $k = { 
        id => 1,
        ssn => '999-99-9999',
        first_name => 'Alice',
        last_name => 'Zoltan',
        address => '360 5 Avenue, Suite 1299',
        city => 'New York',
        state => 'NY',
        zip => '10001',
    };
    $href = $obj->record(1);
    is_deeply($href, $k, "'sep_char' set to pipe works");
    $k = { 
        id => 7,
        ssn => '999-99-9993',
        first_name => 'Guinevere',
        last_name => 'Tyler',
        address => '1 Kodiak Hwy',
        city => 'Kodiak',
        state => 'AK',
        zip => '98989',
    };
    $href = $obj->record(7);
    is_deeply($href, $k, "'sep_char' set to pipe works");
}
