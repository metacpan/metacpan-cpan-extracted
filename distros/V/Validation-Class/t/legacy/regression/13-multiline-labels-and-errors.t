use Test::More tests => 5;

package MyVal;

use Validation::Class;

field name => {
    required => 1,
    label    => q(
        This is a test of a particularly long
        label string
    ),
    error => q(
        The name parameter is required, in order
        to use this parameter you must kill three goats
        and eat the flesh of an african albino tree spider
    )
};

package main;

use strict;
use warnings;

my $v = MyVal->new(params => {});

ok $v, 'initialization successful';

ok $v->fields->{name}->{label} !~ /[\n\t\r]/,
  'label does not have new-lines, carriage-returns and tabs';
ok $v->fields->{name}->{label} !~ /\s{2,}/,
  'label does not have consecutive spaces';
ok $v->fields->{name}->{error} !~ /[\n\t\r]/,
  'error does not have new-lines, carriage-returns and tabs';
ok $v->fields->{name}->{error} !~ /\s{2,}/,
  'error does not have consecutive spaces';
