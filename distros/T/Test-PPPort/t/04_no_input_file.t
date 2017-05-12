use strict;
use warnings;
use Test::More tests => 2;
use Test::PPPort;

use File::Spec;

chdir File::Spec->catfile(qw/ . t sandbox no_input_file /);
do {
    no warnings 'redefine';
    local *Test::Builder::skip_all = sub {
        ok(1, 'skip_all: ' . $_[1]);
        like($_[1], qr/No such XS files/, 'message');
    };
    local *Test::Builder::plan = sub {
        ok(0, 'why called plan method?');
    };
    ppport_ok;
};
