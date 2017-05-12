use strict;
use warnings;

use Test::More tests => 7;

# Load the module.
use_ok 'Test::Fixme';

{    # Check that bad input is not accepted.
    ok !defined Test::Fixme::scan_file(), "no input";
    ok !defined Test::Fixme::scan_file( match => 'TEST' ), "no match";
    ok !defined Test::Fixme::scan_file( file => 't/dirs/normal/one.txt' ),
      "no file";

}

{    # Scan an empty file to get an empty arrayref.
    my $arrayref = Test::Fixme::scan_file(
        file  => 't/dirs/normal/four.pod',
        match => 'TEST'
    );
    ok eq_array( $arrayref, [] ), "empty file, empty array";
}

{    # Scan a file where there should be one hit.
    my $arrayref = Test::Fixme::scan_file(
        file  => 't/dirs/normal/one.txt',
        match => 'ijk'
    );

    my $expected = [
        {
            line  => 2,
            text  => "ghijkl",
            file  => 't/dirs/normal/one.txt',
            match => 'ijk'
        }
    ];

    ok eq_array( $arrayref, $expected ), "find one result";
}

{    # scan file that should have several hits.
    my $arrayref = Test::Fixme::scan_file(
        file  => 't/dirs/normal/two.pl',
        match => 'TEST'
    );

    my $expected = [
        {
            match => 'TEST',
            file  => 't/dirs/normal/two.pl',
            line  => 8,
            text  => "# TEST - test 1 (line 8)."
        },
        {
            match => 'TEST',
            file  => 't/dirs/normal/two.pl',
            line  => 10,
            text  => "# TEST - test 2 (line 10)."
        },
    ];

    ok eq_array( $arrayref, $expected ), "find two results";
}
