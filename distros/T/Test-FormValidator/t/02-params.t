use strict;

use Test::More 'no_plan';

use Test::FormValidator;

my $tfv = Test::FormValidator->new;

# SYNTAX CHECKS for _ok methods

# test to make sure that the various methods that require check be called first
# do so

eval {
    $tfv->missing_ok([]);
};
ok($@, "prevented from calling missing_ok before check");
eval {
    $tfv->invalid_ok([]);
};
ok($@, "prevented from calling invalid_ok before check");

eval {
    $tfv->valid_ok([]);
};
ok($@, "prevented from calling valid_ok before check");

eval {
    $tfv->html_ok('somefile');
};
ok($@, "prevented from calling html_ok before profile");


# test that various _ok functions validate their input

$tfv->check({}, {});

eval {
    $tfv->check_ok();
};
ok($@, "prevented from calling check_ok without input");
eval {
    $tfv->check_ok('description');
};
ok($@, "prevented from calling check_ok without input hashref");

eval {
    $tfv->check_not_ok();
};
ok($@, "prevented from calling check_not_ok without input");

eval {
    $tfv->check_not_ok('description');
};
ok($@, "prevented from calling check_not_ok without input hashref");


eval {
    $tfv->missing_ok();
};
ok($@, "prevented from calling missing_ok without fields");

eval {
    $tfv->missing_ok('bubba');
};
ok($@, "prevented from calling missing_ok with invalid fields");

eval {
    $tfv->invalid_ok();
};
ok($@, "prevented from calling invalid_ok without fields");

eval {
    $tfv->invalid_ok('bubba');
};
ok($@, "prevented from calling invalid_ok with invalid fields");

eval {
    $tfv->valid_ok();
};
ok($@, "prevented from calling valid_ok without fields");

eval {
    $tfv->valid_ok('bubba');
};
ok($@, "prevented from calling valid_ok with invalid fields");

$tfv->profile({});
eval {
    $tfv->html_ok();
};
ok($@, "prevented from calling html_ok without filename");

eval {
    $tfv->html_ok('bubba');
};
ok($@, "prevented from calling html_ok with non-existing file");

eval {
    $tfv->html_ok('bubba', sub { 'boo!' }, 'bubba');
};
ok($@, "prevented from calling html_ok with bad second option");

eval {
    $tfv->html_ok('bubba', { }, 'bubba');
};
ok($@, "prevented from calling html_ok with empty options");

eval {
    $tfv->html_ok('bubba', { ignore => sub { 'boo!' } }, 'bubba');
};
ok($@, "prevented from calling html_ok with bad ignore spec");

