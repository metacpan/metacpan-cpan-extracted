use strict;

use Test::More tests => 4;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mimi;

my $value = not defined &prereq_ok;
main::ok( $value, 'Test::Prereq has not imported yet' );

require Test::Prereq;
Test::Prereq->import;

main::ok( defined &prereq_ok, 'Test::Prereq imported prereq_ok' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Buster;

$value = not defined &prereq_ok;
main::ok( $value, 'Test::Prereq::Build has not imported yet' );

require Test::Prereq::Build;
Test::Prereq->import;

main::ok( defined &prereq_ok, 'Test::Prereq::Build imported prereq_ok' );
