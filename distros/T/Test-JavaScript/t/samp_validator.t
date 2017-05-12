#!/usr/bin/perl

use strict;
use warnings;
use Test::JavaScript tests => 15;

my $class_dec = <<EOT;
Validator = function () {
    return this;
}

Validator.prototype = new Object;

Validator.prototype.isNum = function (num) {
    return String(num).match(/^[\\d.]+\$/);
}

Validator.prototype.isHex = function (num) {
    return String(num).match(/^[A-Fa-f0-9]+\$/) != null;
}
EOT

js_ok($class_dec, "define the Validator class");
js_ok("var validator = new Validator", "create a new validator object");

js_ok("validator.isNum(3)", "3 is a number");
js_ok("validator.isNum(300000000000000)", "300000000000000 is a number");
js_ok("validator.isNum(32432487987)", "32432487987 is a number");
js_ok("validator.isNum(3.24)", "3.24 is a number");
js_ok("!validator.isNum('monkey')", "'monkey' is not a number");
js_ok("!validator.isNum('2834A89')", "'2834A89' is not a number");
js_ok("!validator.isNum('a.4')", "'a.4' is not a number");
js_ok("!validator.isNum('a1')", "'a1' is not a number");
js_ok("!validator.isNum('1a')", "'1a' is not a number");

js_ok("validator.isHex(3)", "3 is hex");
js_ok("validator.isHex('3A')", "3A is hex");
js_ok("validator.isHex('D3FF4')", "D3FF4 is hex");
js_ok("!validator.isHex('3AZ')", "3AZ is not hex");

