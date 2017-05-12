use strict;
use warnings;

my ( $out, $err ) = @ARGV;
print $out || "out line 1\nout line 2";
print STDERR $err || "err line 1\nerr line 2";

