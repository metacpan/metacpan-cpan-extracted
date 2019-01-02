use strict;
use warnings;

use Test::More;
use Variable::Declaration;

eval {
    Variable::Declaration::croak('some', 'message');
};

like $@, qr!^somemessage at ([^\s]+) line \d\.!;

done_testing;
