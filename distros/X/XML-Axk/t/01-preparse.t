#!perl
# 01-preparse.t

use 5.020;
use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture_stdout';
use File::Spec;

BEGIN {
    use_ok( 'XML::Axk::Preparse' ) || print "Bail out!\n";
}

#sub localpath {
#    state $voldir = [File::Spec->splitpath(__FILE__)];
#    return File::Spec->catpath($voldir->[0], $voldir->[1], shift)
#}

# Convenient alias
local *pp = sub { goto &XML::Axk::Preparse::preparse; };

my $srTest;

$srTest = pp('foo', <<'EOT');
#!x -L1
EOT
like($$srTest, qr/^use XML::Axk::L::L1/);
like($$srTest, qr/^#line.*foo/m);

$srTest = pp('foo', <<'EOT');
#!x -L 1
EOT
like($$srTest, qr/^use XML::Axk::L::L1/);
like($$srTest, qr/^#line.*foo/m);

$srTest = pp('foo', <<'EOT');
#!x --language 1
EOT
like($$srTest, qr/^use XML::Axk::L::L1/);
like($$srTest, qr/^#line.*foo/m);

$srTest = pp('foo', <<'EOT');
-L1
EOT
like($$srTest, qr/^use XML::Axk::L::L1/);
like($$srTest, qr/^#line.*foo/m);

$srTest = pp('foo', <<'EOT');
-L 1
EOT
like($$srTest, qr/^use XML::Axk::L::L1/);
like($$srTest, qr/^#line.*foo/m);

$srTest = pp('foo', <<'EOT');
--language 1
EOT
like($$srTest, qr/^use XML::Axk::L::L1/);
like($$srTest, qr/^#line.*foo/m);


done_testing();

# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=1: #
