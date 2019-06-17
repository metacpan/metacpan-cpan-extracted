use strict;
use warnings;

use Test::More tests => 11;
use WWW::FieldValidator ();

my $validator = WWW::FieldValidator->new( WWW::FieldValidator::REGEX_MATCH,
    'Value must be 0 to 5', '^[0-5]$' );

# TEST
ok !$validator->validate('donkey'), 'Not donkey';

# TEST
ok !$validator->validate(''), 'Not empty string';

# TEST
ok !$validator->validate('55'), 'Not double digit';

# TEST
ok !$validator->validate('-5'), 'Not negative int';

# TEST*6
for my $data ( 0 .. 5 )
{
    ok $validator->validate($data), "$data is fine";
}

# TEST
ok !$validator->validate('6'), 'Not 6';
