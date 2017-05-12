use Test::More;
use Test::JSON::Entails;
use Test::Builder::Tester tests => 1;

my $i = 1;
foreach my $item (
  # no JSON object or HASH reference
    [ input    => [ "[]", "{}", ] ], 
    [ entailed => [ "{}", "[]" ] ],
    [ input    => [ [ ], { } ] ], 
    [ entailed => [ { }, [ ] ] ], 
  # invalid JSON
    [ input    => [ "", { } ] ], 
    [ entailed => [ { }, "-" ] ], 
) {
    my $which = $item->[0];
    
    test_out("not ok $i - $which");
    test_fail(+4);
    test_diag( "$which was not " . 
        ($i < 5 ? "JSON object or HASH reference" : "valid JSON") 
    );
    entails $item->[1]->[0], $item->[1]->[1], $which;
    $i++;
}

test_test("input/entailed must be JSON objects or HASH references");
