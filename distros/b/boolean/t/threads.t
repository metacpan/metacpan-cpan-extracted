use Test::More;
use strict;
use lib 'lib';

use Config;
BEGIN { plan skip_all => "requires threads" unless $Config{usethreads} };

use threads;

plan tests => 8;

use boolean ':all';

my $true = true;
my $false = false;

sub ok_from_thread($) {
    local $Test::Builder = $Test::Builder::Level + 1;
    my $code = shift;
    ok( threads->create(eval "sub { $code }")->join(), $code );
};

ok_from_thread "isTrue(true)";
ok_from_thread "isFalse(false)";
ok_from_thread "isBoolean(true)";
ok_from_thread "isBoolean(false)";
ok_from_thread "isTrue(\$true)";
ok_from_thread "isFalse(\$false)";
ok_from_thread "isBoolean(\$true)";
ok_from_thread "isBoolean(\$false)";
