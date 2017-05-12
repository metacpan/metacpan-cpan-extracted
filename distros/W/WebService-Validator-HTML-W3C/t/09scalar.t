# $Id$

use Test::More tests => 8;

use WebService::Validator::HTML::W3C;

my $valid = qq{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title></title>
</head>
<body>

</body>
</html>
};

my $invalid = qq{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title></title>
</head>
<body>

<div>
    
</body>
</html>
};

my $v = WebService::Validator::HTML::W3C->new(
            http_timeout    =>  10,
        );

SKIP: {
    skip "TEST_AUTHOR environment variable not defined", 8 unless $ENV{ 'TEST_AUTHOR' };

    ok($v, 'object created');

    ok( !$v->validate_markup(), 'fails if no markup' );
    is( $v->validator_error(), 'You need to supply markup to validate',
        'you need to supply markup error' );

    my $r = $v->validate_markup( $valid );

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 5;
        }
    }

    ok($r, 'validated valid scalar');
    ok($v->is_valid(), 'valid scalar is valid');

    $r = $v->validate_markup( $invalid );

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 3;
        }
    }

    ok($r, 'validated invalid scalar');
    ok(!$v->is_valid(), 'invalid scalar is invalid');
    is( $v->num_errors(), 1, 'correct number of errors');
}
