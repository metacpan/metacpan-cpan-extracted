#!perl

use strict;
use Test::Builder::Tester;
use Test::More tests => 2;

use Data::Dumper;

use lib qw(lib);

use Test::HTML::Form;

my $filename = 't/form_with_errors.html';

test_out("not ok 1 - Not found wrong link in HTML");
test_err("#   Failed test 'Not found wrong link in HTML'\n#   at t/failures.t line 17.\n# Expected at least one tag of type 'a or link' in file t/form_with_errors.html matching condition, but got 0");
link_matches ($filename,'/foo/select_foo.html?id=87654321','Not found wrong link in HTML');
test_test('failed link match returns false correctly');

test_out("not ok 1 - date matches select");
test_err("#   Failed test 'date matches select'\n#   at t/failures.t line 22.\n# Expected form to contain field 'day_post_date' and have option with value of '19' selected but not found in file t/form_with_errors.html ");
form_select_field_matches($filename,{ field_name => 'day_post_date', selected => 19, form_name => undef}, 'date matches select');
test_test('failed select match returns false correctly');
