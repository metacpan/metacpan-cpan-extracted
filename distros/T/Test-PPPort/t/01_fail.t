use strict;
use warnings;
use Test::More tests => 3;
use Test::PPPort;

use File::Spec;

chdir File::Spec->catfile(qw/ . t sandbox fail /);
do {
    no warnings 'redefine';
    my $ok = \&Test::Builder::ok;
    local *Test::Builder::ok = sub {
        $ok->($_[0], !$_[1], 'is fail');
    };
    local *Test::Builder::plan = sub {
        my($self, %plan) = @_;
        $ok->($_[0], ($plan{tests} == 1), 'plan tests => 1');
    };
    local *Test::Builder::diag = sub {
        $ok->($_[0], $_[1], 'show the result data');
    };
    ppport_ok;
};
