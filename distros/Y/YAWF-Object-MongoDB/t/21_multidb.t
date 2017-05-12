use strict;
use warnings;

use Test::More tests => 152;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Car');

# $YAWF::Object::MongoDB::DEBUG = 1;

# Test using the same collection in three DBs
my @dbs = (map { 'Y_O_M_t05_'.$_; } (1..3));

# Clean up
for (@dbs) {
    $t::lib::Car::DATABASE = $_;
    eval { t::lib::Car->_database->drop; };
    ok (1,'Drop database '.$_);
}

my @dbh;
# Create some objects
for my $db (@dbs) {
    $t::lib::Car::DATABASE = $db;
    is(t::lib::Car->_database->{name},$db,$db.' Database name in class');
    is(t::lib::Car->_database->run_command({dbstats => 1})->{db},$db,$db.' Database name from server');
    is(t::lib::Car->_collection->{_database}->run_command({dbstats => 1})->{db},$db,$db.' Database name from server (collection)');
    push @dbh,t::lib::Car->_database;
    for my $n (1..3) {
        my $obj = t::lib::Car->new;
        ok($obj,$db.' create object '.$n);
        is($obj->_database->{name},$db,$db.' Database name in handle');
        $obj->set_column('obj_db',$db);
        is($obj->get_column('obj_db'),$db,$db.' Save database name in object');
        is($obj->set_column('obj_n',$n),$n,$db.' Save number in object');
        ok($obj->flush,$db.' Flush object');
    }
}

# Check dbh's
for $a (0..$#dbh) {
    for $b (0..$#dbh) {
        next if $a == $b;
        isnt($dbh[$a],$dbh[$b],"Compare dbh $a vs. $b");
    }
}

# Check the objects
for my $db (@dbs) {
    $t::lib::Car::DATABASE = $db;
    is(t::lib::Car->_database->run_command({dbstats => 1})->{db},$db,$db.' Database name from server');
    for my $n (1..3) {
        my $obj = t::lib::Car->new(obj_n => $n);
        is($obj->_database->{name},$db,$db.' Database name in handle');
        is($obj->_database->run_command({dbstats => 1})->{db},$db,$db.' Database name from server');
        ok($obj,$db.' fetch object '.$n);
        is($obj->get_column('obj_db'),$db,$db.' check database name');
        is($obj->get_column('obj_n',$n),$n,$db.' check number');
    }
}

# Check the objects (2)
for my $n (1..3) {
    for my $db (@dbs) {
        $t::lib::Car::DATABASE = $db;
        my $obj = t::lib::Car->new(obj_n => $n);
        is($obj->_database->{name},$db,$db.' Database name in handle');
        ok($obj,$db.' fetch object '.$n);
        is($obj->get_column('obj_db'),$db,$db.' check database name');
        is($obj->get_column('obj_n',$n),$n,$db.' check number');
    }
}

# Clean up
for my $db (@dbs) {
    $t::lib::Car::DATABASE = $db;
    ok (t::lib::Car->_database->drop,'Drop database '.$db);
}
