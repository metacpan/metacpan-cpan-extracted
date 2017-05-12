use strict;
use warnings;
use Test::More tests => 20;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

UR::Object::Type->define(
    class_name => 'URT::Office',
    id_by => 'office_id',
    has => ['office_number'],
);
    
UR::Object::Type->define(
    class_name => 'URT::Boss',
    id_by => 'boss_id',
    has => [
        name => { is => 'Text' },
        office => { is => 'URT::Office', id_by => 'office_id' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Employee',
    id_by => 'emp_id',
    has => [
        name => { is => 'Text' },
        boss => { is => 'URT::Boss', id_by => 'boss_id' },
        boss_name => { via => 'boss', to => 'name' },
        boss_office => { is => 'URT::Office', via => 'boss', to => 'office' },
        boss_office_number => { via => 'boss_office', to => 'office_number' },
    ],
);


my $o = URT::Office->create(office_number => 123);
ok($o, 'Created office 123');

my $b = URT::Boss->create(name => 'Montgomery', office => $o);
ok($b, 'Created boss with an office');
is($b->office_id, $o->id, 'Boss office_id is correct');
is($b->office, $o, 'Boss office is correct');

my $e = URT::Employee->create(name => 'Homer', boss => $b);
ok($e, 'Created an employee with a boss');
is($e->boss_id, $b->id, 'Employee boss_id is correct');
is($e->boss, $b, 'Employee boss is correct');
is($e->boss_office, $o, 'Employee boss_office is correct');

my $bx = URT::Employee->define_boolexpr(name => 'Mindy', boss_name => 'Montgomery');
ok($bx, 'Created BoolExpr with an Employee name and boss_name');

$bx = URT::Employee->define_boolexpr(name => 'Mindy', boss_office => $o);
ok($bx, 'Created BoolExpr with an Employee name and boss_office');

$e = URT::Employee->create(name => 'Lenny', boss_office => $o);
ok($e, 'Created an employee with a boss_office');
is($e->boss_id, $b->id, 'Employee boss_id is correct');
is($e->boss, $b, 'Employee boss is correct');
is($e->boss_office, $o, 'Employee boss_office is correct');


$e = URT::Employee->create(name => 'Carl', boss => $b, boss_office => $o);
ok($e, 'Created an employee with a consistent boss and boss_office');
is($e->boss_id, $b->id, 'Employee boss_id is correct');
is($e->boss, $b, 'Employee boss is correct');
is($e->boss_office, $o, 'Employee boss_office is correct');



my $o2 = URT::Office->create(office_number => 456);
ok($o2, 'Created office 456');

$e = eval { URT::Employee->create(name => 'Frank', boss => $b, boss_office => $o2) };
ok(!$e, 'Correctly couldn not create an employee with conflicting boss and boss_office');
