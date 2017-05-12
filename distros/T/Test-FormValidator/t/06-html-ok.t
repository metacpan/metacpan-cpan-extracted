
use strict;

use Test::Builder::Tester 'tests' => 5;
use Test::More;
use Data::FormValidator::Constraints qw(:closures);
use Test::FormValidator;

my $tfv = Test::FormValidator->new;

$tfv->profile({
    required => [qw(
        pass1
        pass2
        comments
        newsletter
    )],
    optional => [qw(
        name
        food
        email
    )],
});


test_out("ok 1 - html good");
$tfv->html_ok('t/testform.html', "html good");
test_test("html_ok - caught passed test of valid html form");


$tfv->profile({
    required => 'pass1',
    optional => [qw(
        food
        email
    )],
});


test_out("not ok 1 - html good");
$tfv->html_ok('t/testform.html', "html good");
test_diag("Profile fields: email, food, pass1");
test_diag("HTML fields:    comments, email, food, name, newsletter, pass1, pass2");
test_fail(-3);
test_test("html_ok - caught failed test of invalid html form (unmatched fields in template) plus diagnostics");

$tfv->profile({
    required => [qw(
        fred
        pass1
        pass2
        comments
        newsletter
    )],
    optional => [qw(
        barney
        name
        food
        email
    )],
});


test_out("not ok 1 - html good");
$tfv->html_ok('t/testform.html', "html good");
test_test(name => "html_ok - caught failed test of invalid html form (unmatched fields in profile)", skip_err => 1);



# Test with list of ignore fields
$tfv->profile({
    required => [qw(
        food
        bubba
        email
    )],
    optional => 'pass1',
});


test_out("ok 1 - html good");
$tfv->html_ok('t/testform.html', { ignore => [qw(pass2 comments bubba newsletter name)] }, "html good");
test_test("html_ok - caught passed test of invalid html but with list of ignored fields");



# Test with regex for ignore fields
$tfv->profile({
    required => [qw(
        food
        bubba
        email
        name
    )],
    optional => 'comments',
});


test_out("ok 1 - html good");
$tfv->html_ok('t/testform.html', { ignore => qr/(pass)|(bub)|(let)/ }, "html good");
test_test("html_ok - caught passed test of invalid html but with regex for ignored fields");

