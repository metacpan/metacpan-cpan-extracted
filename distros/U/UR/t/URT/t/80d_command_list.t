use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 19;


my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, 'Create database');

$dbh->do('create table workplace (workplace_id integer PRIMARY KEY NOT NULL, name varchar NOT NULL)');
$dbh->do("insert into workplace values (1, 'Acme')");
$dbh->do("insert into workplace values (2, 'CoolCo')");

$dbh->do('create table person (person_id integer PRIMARY KEY NOT NULL, name varchar NOT NULL, workplace_id integer REFERENCES workplace(workplace_id))');
$dbh->do("insert into person values (1, 'Bob',1)");
$dbh->do("insert into person values (2, 'Fred',2)");
$dbh->do("insert into person values (3, 'Mike',1)");
$dbh->do("insert into person values (4, 'Joe',2)");

UR::Object::Type->define(
    class_name => 'URT::Workplace',
    id_by => 'workplace_id',
    has => [
        name => { is => 'String' },
        uc_name => { calculate_from => ['name'], calculate => q( return uc $name ) },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'workplace',
);
UR::Object::Type->define(
    class_name => 'URT::Person',
    id_by => 'person_id',
    has => [
        name => { is => 'String' },
        uc_name => { calculate_from => ['name'], calculate => q( return uc $name ) },
        workplace => { is => 'URT::Workplace', id_by => 'workplace_id' },
        workplace_name => { via => 'workplace', to => 'name' },
        workplace_uc_name => { via => 'workplace', to => 'uc_name' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
);

my $counter = 0;
sub URT::Person::a_sub { return $counter++ }

my @p = URT::Person->__meta__->properties;

my($fh,$output);
$output = '';
open($fh, '>', \$output);
# Query involving only one class, filter is a direct property, show has a calculated property
my $cmd = UR::Object::Command::List->create(subject_class_name => 'URT::Workplace',
                                            filter => 'name=CoolCo',
                                            show   => 'id,uc_name',
                                            output => $fh);
ok($cmd, 'Create a lister command for Workplace.  filter has direct, show has calculated');
ok($cmd->execute(), 'execute');

my $expected_output = <<EOS;
ID   UC_NAME
--   -------
2    COOLCO
EOS

is($output, $expected_output, 'Output is as expected');

$output = '';
open($fh, '>', \$output);
# filter is a calculated property, show has both calculated and direct properties
$cmd = UR::Object::Command::List->create(subject_class_name => 'URT::Workplace',
                                         filter => 'uc_name=COOLCO',
                                         show   => 'id,uc_name,name',
                                         output => $fh);
ok($cmd, 'Create a lister command for Workplace.  filter has calculated, show has direct and calculated');
ok($cmd->execute(), 'execute');

$expected_output = <<EOS;
ID   UC_NAME   NAME
--   -------   ----
2    COOLCO    CoolCo
EOS

is($output, $expected_output, 'Output is as expected');


$output = '';
open($fh, '>', \$output);
# Query involving two joined tables, filter is a via/to property, show has calculated and via/to properties
$cmd = UR::Object::Command::List->create(subject_class_name => 'URT::Person',
                                         filter => 'workplace_name=Acme',
                                         show   => 'uc_name,workplace_uc_name',
                                         output => $fh);
ok($cmd, 'Create a lister command for Person.  filter has via/to, show has calculated and via/to');
ok($cmd->execute(), 'execute');

$expected_output = <<EOS;
UC_NAME   WORKPLACE_UC_NAME
-------   -----------------
BOB       ACME
MIKE      ACME
EOS

is($output, $expected_output, 'Output is as expected');



$output = '';
open($fh, '>', \$output);
# Query involving two joined tables, filter is a direct property, show has direct and via/to property
$cmd = UR::Object::Command::List->create(subject_class_name => 'URT::Person',
                                         filter => 'name~%o%',
                                         show   => 'name,workplace_name',
                                         output => $fh);
ok($cmd, 'Create a lister command for Person.  filter has direct prop, show has direct and via/to');
ok($cmd->execute(), 'execute');

$expected_output = <<EOS;
NAME   WORKPLACE_NAME
----   --------------
Bob    Acme
Joe    CoolCo
EOS

is($output, $expected_output, 'Output is as expected');



$output = '';
open($fh, '>', \$output);
# Query involving one table and calling a subroutine directly
$cmd = UR::Object::Command::List->create(subject_class_name => 'URT::Person',
                                         filter => 'name~%o%',
                                         show   => 'name,$o->a_sub',
                                         output => $fh);
ok($cmd, 'Create a lister command for Person with a subroutine in the show list');
ok($cmd->execute(), 'execute');

$expected_output = <<'EOS';
NAME   ($O->A_SUB)
----   -----------
Bob    0
Joe    1
EOS

is($output, $expected_output, 'Output is as expected');


$output = '';
open($fh, '>', \$output);
$cmd = UR::Object::Command::List->create(subject_class_name => 'URT::Person',
                                         show     => 'id,name,workplace_name',
                                         order_by => 'workplace_name',
                                         output   => $fh);
ok($cmd, 'Create a lister command for Person with a custom order-by');
ok($cmd->execute(), 'execute');

$expected_output = <<'EOS';
ID   NAME   WORKPLACE_NAME
--   ----   --------------
1    Bob    Acme
3    Mike   Acme
2    Fred   CoolCo
4    Joe    CoolCo
EOS

is($output, $expected_output, 'Output is as expected');

