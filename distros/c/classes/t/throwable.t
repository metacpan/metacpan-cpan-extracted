# $Id: throwable.t 140 2006-09-26 09:23:29Z rmuhle $

use strict;

use Test::More;

eval 'use Test::Exception';
if ($@) {
    plan skip_all => "Test::Exception needed";
} else {
    plan tests => 3;
}

use_ok 'classes';
use classes::Test ':all';

lives_ok( sub {
    package MyThrowable;
    use classes mixes => 'classes::Throwable';
}, 'MyThrowable mixed in classes::Throwable');

is_throwable MyThrowable;

