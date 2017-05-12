#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Test::Warn;

use Util::Underscore;

subtest 'Carp identity tests' => sub {
    plan tests => 4;

    for my $sub (qw/carp cluck croak confess/) {
        no strict 'refs';
        ok \&{"_::$sub"} == \&{"Carp::$sub"}, "_::$sub";
    }
};

subtest 'formatted Carp functions' => sub {
    plan tests => 4;
    warning_is { _::carpf "1%s3%d",  2, 4 } '1234', "_::carpf";
    warning_is { _::cluckf "1%s3%d", 2, 4 } '1234', "_::cluckf";
    throws_ok { _::croakf "1%s3%d",   2, 4 } qr/^1234\b/, "_::croakf";
    throws_ok { _::confessf "1%s3%d", 2, 4 } qr/^1234\b/, "_::confessf";
};

subtest 'Try::Tiny identity tests' => sub {
    for my $sub (qw/try catch finally/) {
        no strict 'refs';
        ok \&{"_::$sub"} == \&{"Try::Tiny::$sub"}, "_::$sub";
    }
};
