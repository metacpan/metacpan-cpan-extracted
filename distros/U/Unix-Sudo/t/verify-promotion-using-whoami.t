use strict;
use warnings;
use Taint::Runtime qw(enable taint_enabled);

use Test::More;

use Capture::Tiny qw(capture);

use Unix::Sudo qw(sudo);

use lib 't/lib';
use sudosanity;

sudosanity::checks && do {
    ok(taint_enabled, "Tainting is enabled in the calling context");
    my($stdout, $stderr, $rv) = capture {
        sudo {
            eval "use Taint::Runtime qw(disable)";
            print `whoami`;
        }
    };
    chomp($stdout);
    is($stdout, 'root', "ran 'whoami' as root");
    ok(taint_enabled, "Tainting is still enabled in the calling context");
};

done_testing();
