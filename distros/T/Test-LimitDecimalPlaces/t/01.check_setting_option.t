use strict;
use warnings;
use utf8;

BEGIN {
    use Test::Exception;
    use Test::LimitDecimalPlaces tests => 4;
}

lives_ok { Test::LimitDecimalPlaces->import() };
lives_ok { Test::LimitDecimalPlaces->import( num_of_digits => 5 ) };
throws_ok { Test::LimitDecimalPlaces->import( num_of_digits => -1 ) }
    qr/Value of limit number of digits must be a number greater than or equal to zero./;
throws_ok { Test::LimitDecimalPlaces->import( _tests => 5, num_of_digits => 5 ) }
    qr/Test::LimitDecimalPlaces option must be specified first./;
