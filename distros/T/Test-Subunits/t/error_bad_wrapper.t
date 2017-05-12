use 5.010;
use strict;
use warnings;
use lib 'tlib';

use Test::More;
plan tests => 4;


# Test for syntax error (bad wrapper specification after ##{ or ##:)...

ok !eval q{ use Test::Subunits 'BadWrapperBlock'; 1; }
    => 'Detected bad wrapper after ##{';

like $@, qr/\AInvalid wrapper specification:\s*##\{/ => 'Correct error message';


ok !eval q{ use Test::Subunits 'BadWrapperPara'; 1; }
    => 'Detected bad wrapper after ##:';

like $@, qr/\AInvalid wrapper specification:\s*##:/ => 'Correct error message';

done_testing();


