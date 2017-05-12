use Test::More;
sub foo { 1 }

package X;
package main;

is foo(), 1;
done_testing;


