# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;
BEGIN { plan tests => 2 };
use base::Glob;
ok(1);

package Class::Apple;
sub number { 2 };
package Class::Orange;
sub number { 3 };
package main;
use base::Glob qw(Class::A*);
eval { (main->number() == 2) } ? ok(1) : ok(0);
