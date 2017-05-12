# -*-perl -*-
use Test::More tests => $INC{"Devel/Cover.pm"} ? 9 : 7;
use optimize;

package foo;
BEGIN { optimize->register(sub { Test::More::pass() }, "bar")};
$i++;
package bar;
$i++;
$i++;
$i++;
package yeah;
$i++;
