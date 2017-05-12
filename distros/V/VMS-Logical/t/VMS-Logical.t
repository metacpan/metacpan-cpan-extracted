#########################

use Data::Dumper;
use constant TABLE_NAME => 'VMS_LOGICAL_TABLE';
use constant LOGICAL_NAME => 'VMS_LOGICAL_TEST';

use Test::More tests => 23;
BEGIN { use_ok('VMS::Logical') };

#########################

# get a value to store in the logical
my $time = time();

# create a table
my $x = VMS::Logical::create_table({table=>TABLE_NAME,
				    acmode=>'SUPERVISOR',
				    partab=>'LNM$PROCESS_DIRECTORY'});
ok(defined($x), 'create table: returns a value');
ok($x eq TABLE_NAME, 'create table: returns table name');

# define a logical in it
$x = VMS::Logical::define({lognam=>LOGICAL_NAME,
			   acmode=>'SUPERVISOR',
			   table=>TABLE_NAME,
			   equiv=>[{string=>$time}]});
ok(defined($x), 'define logical: returns a value');
ok($x eq TABLE_NAME, 'define logical: returns table name');

# translate the logical we just created
$x = VMS::Logical::translate({lognam=>LOGICAL_NAME,
			      table=>TABLE_NAME});
ok(defined($x), 'translate: returns a value');
ok(ref($x) eq 'HASH', 'translate: returns a hash');
ok(exists($x->{sts}), 'translate: status returned');
ok($x->{sts} == 1, 'translate: successful');
ok(exists($x->{table}), 'translate: table name returned');
ok($x->{table} eq TABLE_NAME, 'translate: correct table');
ok(exists($x->{equiv}), 'translate: equivalences returned');
ok(ref($x->{equiv}) eq 'ARRAY', 'translate: equivalence is array');
ok(@{$x->{equiv}} == 1, 'translate: equivalence array has one entry');
ok(ref($x->{equiv}[0]) eq 'HASH', 'translate: first equivalence is a hash');
ok(exists($x->{equiv}[0]{string}), 'translate: equiv hash returns string');
ok($x->{equiv}[0]{string} eq $time, 'translate: string is correct');

# deassign the logical
$x = VMS::Logical::deassign({lognam=>LOGICAL_NAME,
                             table=>TABLE_NAME,
                             acmode=>'SUPERVISOR'});
ok(defined($x), 'deassign: returns a value');
ok($x & 1, 'deassign: successful');

# make sure it doesn't translate anymore
$x = VMS::Logical::translate(LOGICAL_NAME);
ok(!defined($x), 'translate: returns undef');
ok($! == 444, 'translate: error code correct');

# delete the table
$x = VMS::Logical::deassign({lognam=>TABLE_NAME,
			     table=>'LNM$PROCESS_DIRECTORY',
			     acmode=>'SUPERVISOR'});
ok(defined($x), 'delete table: returns a value');
ok($x & 1, 'delete table: successful');
