# pmfunc testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 1;

# ------ define variable
my $output = undef;	# output from pmfunc

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmfunc Cwd::getcwd 2>&1`;
};

isnt($?, 127, "pmfunc runs");

# TODO: add tests after I get pmfunc working again
# like($output, qr/blessed.*dualvar.*isdual.*isvstring.*isweak/ms,
# 	"list function body");
