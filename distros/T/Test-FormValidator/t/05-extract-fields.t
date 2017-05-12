
use strict;

use Test::More 'no_plan';

use Test::FormValidator;

my $tfv = Test::FormValidator->new;

my @fields = $tfv->_extract_form_fields_from_html('t/testform.html');

my @expected_fields = sort qw(
    name
    food
    email
    pass1
    pass2
    comments
    newsletter
);

is_deeply(\@fields, \@expected_fields, 'extracted fields from testform.html');
