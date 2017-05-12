use strict;
use lib 't', 'inc';
use Test::More tests => 3;
use onlyTest;
use File::Spec;
no warnings 'once';

my $versionlib;
BEGIN {
    $versionlib = File::Spec->rel2abs(File::Spec->catdir(qw(t alternate)));
}

use only {versionlib => $versionlib};
eval qq{use only _Boom => '0.77'};
is($@, '');
is($_Boom::VERSION, '0.77');
is($_Boom::boom, 'Bada-Boom');
