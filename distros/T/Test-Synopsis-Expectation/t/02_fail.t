#!perl

use strict;
use warnings;
use Test::Builder::Tester;
use Test::Synopsis::Expectation;

test_out(
    'ok 1 - Syntax OK: *main::DATA (SYNOPSIS Block: 1)',
    'not ok 2 - *main::DATA (SYNOPSIS Block: 1, Line: 1)',
    'ok 3 - Syntax OK: *main::DATA (SYNOPSIS Block: 2)',
    'not ok 4 - *main::DATA (SYNOPSIS Block: 2, Line: 1)',
    'not ok 5 - *main::DATA (SYNOPSIS Block: 2, Line: 2)',
);
synopsis_ok(*DATA);
test_test (name => 'testing used_modules_ok()', skip_err => 1);

done_testing;
__DATA__
=head1 NAME

fail - crazy!!

=head1 SYNOPSIS

    2; # => 1

Of course following is fail!

    1; # => 2
    0; # => success

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
